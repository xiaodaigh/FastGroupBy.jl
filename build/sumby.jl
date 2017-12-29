##############################################################################
##
## sumby...
##
##############################################################################

"""
Perform sum by group
```julia
sumby(df::Union{AbstractDataFrame,NDSparse}, by::Symbol, val::Symbol)
sumby(by::AbstractVector  val::AbstractVector)
```
### Arguments
* `df` : an AbstractDataFrame/NDSparse from which to extract the by and val columns
* `by` : data table column to group by
* `val`: data table column to sum
### Returns
* `::Dict` : A Dict that maps unqiues values of by to sum of val

### Examples
```julia
using FastGroupBy
using DataFrames, IndexedTables, Compat, BenchmarkTools
import DataFrames.DataFrame

const N = 10_000_000; const K = 100

# sumby is faster for DataFrame without missings
srand(1);
@time df = DataFrame(id = rand(1:Int(round(N/K)), N), val = rand(round.(rand(K)*100,4), N));
@belapsed DataFrames.aggregate(df, :id, sum)
@belapsed sumby(df, :id, :val)

```
"""
function sumby!(by::AbstractVector{T},  val::AbstractVector{S}; alg = :auto)::Dict{T,S} where {T, S<:Number}
    l = length(by)

    l == length(val) || throw(ErrorException("length of by and val must be the same"))

    if l == 0
        return Dict{T,S}()
    elseif l == 1
        return Dict{T,S}(by[1], val[1])
    elseif issorted(by)
        return sumby_contiguous(by, val)
    elseif l <= 2^16
        return sumby_sortperm(by, val)
    elseif !isbits(T) || alg == :dict
        return sumby_dict(by, val)
    elseif nthreads() > 1
        return sumby_multi_rs(by, val)
    elseif l <= 50_000_000
        return sumby_radixsort!(by, val)
    else
        # return sumby_radixgroup(by, val)
        return sumby_radixsort!(by, val)
    end
end

"sumby by using radix and counting sort to group by; it's only a partial sort. It's faster for large by"
function sumby_radixgroup!(by::AbstractVector{T},  val::AbstractVector{S}; cutsize = 2048)::Dict{T,S} where {T, S<:Number}
    by_sim = similar(by)
    val1=similar(val)
    o = Forward

    l = length(by)

    if l == 0
        return Dict{T,S}()
    elseif l == 1
        return Dict{T,S}(by[1] => val[1])
    end

    # Make sure we're sorting a bits type
    if !isbits(T)
      error("sumby_nosort on works on bits types (got $T)")
    end

    # Init
    iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE)

    # distinct range to groupby over; initially the whole block is one range
    nextranges = Tuple{Int, Int}[]

    new_small_grps = similar(nextranges)

    push!(nextranges, (1,l))

    for j = 1:iters
        #println(string(j,":",length(nextranges)))
        ranges = nextranges::Array{Tuple{Int, Int}}
        nextranges = Tuple{Int,Int}[]
        if length(ranges) > 0
            for (lo, hi) in ranges
                bin = zeros(UInt32, 2^RADIX_SIZE)

                # Histogram for each element, radix
                for i = lo:hi
                    #v = uint_mapping(o, by[i])
                    idx = Int((by[i] >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1
                    @inbounds bin[idx] += 1
                end

                # Sort!
                len = hi - lo + 1

                # Unroll first data iteration, check for degenerate case
                #v = uint_mapping(o, by[hi])
                idx = Int((by[hi] >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1

                # are all values the same at this radix?
                if bin[idx] == len
                    nextranges = vcat(nextranges, [(lo, hi)])::Array{Tuple{Int, Int}}
                    @inbounds by_sim[lo:hi] = by[lo:hi]
                    @inbounds val1[lo:hi] = val[lo:hi]
                else
                    if lo > 1;  bin[1] += UInt32(lo-1);  end
                    cbin = cumsum(bin)

                    # compute the new ranges for next round
                    tmpr = sort(setdiff(unique(cbin), lo-1))::Vector{Int}
                    tmpnextranges = vcat(nextranges, [(lo,Int(tmpr[1]))], [(Int(a)+1,Int(b)) for (a,b) in zip(tmpr[1:end-1],tmpr[2:end])])::Array{Tuple{Int, Int}}
                    nextranges = filter(x -> x[2] - x[1] + 1 > cutsize, tmpnextranges)::Array{Tuple{Int, Int}}

                    if length(tmpnextranges) != length(nextranges)
                        # this is a small grp just sort it
                        new_small_grps = filter(x -> x[2] - x[1] + 1 <= cutsize, tmpnextranges)
                    end

                    ci = cbin[idx]
                    by_sim[ci] = by[hi]
                    val1[ci] = val[hi]
                    cbin[idx] -= 1

                    # Finish the loop...
                    @inbounds for i in hi-1:-1:lo
                      #v = uint_mapping(o, by[i])
                      idx =Int((by[i] >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1
                      ci = cbin[idx]
                      by_sim[ci] = by[i]
                      val1[ci] = val[i]
                      cbin[idx] -= 1
                    end
                end
            end
            if length(new_small_grps) > 0
                for (lo_nsg, hi_nsg) in new_small_grps
                    @inbounds bytmp = by_sim[lo_nsg:hi_nsg]
                    sp = sortperm(bytmp)
                    bytmp_sorted = bytmp[sp]
                    val1_sorted = val1[lo_nsg:hi_nsg][sp]
                    @inbounds by[lo_nsg:hi_nsg] = bytmp_sorted
                    @inbounds val[lo_nsg:hi_nsg] = val1_sorted
                    @inbounds by_sim[lo_nsg:hi_nsg] = bytmp_sorted
                    @inbounds val1[lo_nsg:hi_nsg] = val1_sorted
                end
                new_small_grps = Int[]
            end
            by, by_sim = by_sim, by
            val, val1 = val1, val
        end
    end

    return sumby_contiguous(by, val)
end

"sumby by sorting the by column using radixsort"
function sumby_radixsort!(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S} where {T, S<:Number}
  
  hi = length(by)

  if hi == 0;  return Dict{T,S}();
  elseif hi == 1;  return Dict{T,S}(by[1] => val[1]);  end

  by_sim = similar(by)
  val1=similar(val)
  lo = 1

  # Make sure we're sorting a bits type
  #TT = Base.Order.ordtype(o, by)
  if !isbits(T)
      throw(error("Radix sort only sorts bits types (got $T)"))
  end

  # Init
  iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE)
  bin = zeros(UInt32, 2^RADIX_SIZE, iters)
  if lo > 1;  bin[1,:] = lo-1;  end

  # Histogram for each element, radix
  for i = lo:hi
    v = by[i]
    for j = 1:iters
        idx = Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1
        @inbounds bin[idx,j] += 1
    end
  end

  # Sort!
  # swaps = 0
  len = hi-lo+1
  for j = 1:iters
      # Unroll first data iteration, check for degenerate case
      v = by[hi]
      idx = Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1

      # are all values the same at this radix?
      if bin[idx,j] == len;  continue;  end

      cbin = cumsum(bin[:,j])
      ci = cbin[idx]
      by_sim[ci] = by[hi]
      val1[ci] = val[hi]

      cbin[idx] -= 1

      # Finish the loop...
      @inbounds for i in hi-1:-1:lo
          v = by[i]
          idx = Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1
          ci = cbin[idx]
          by_sim[ci] = by[i]
          val1[ci] = val[i]
          cbin[idx] -= 1
      end
      by,by_sim = by_sim,by
      val,val1 = val1,val
    #   swaps += 1
  end

  # @inbounds if isodd(swaps)
  #   by,by_sim = by_sim,by
  #   val,val1 = val1,val
  #   for i = lo:hi
  #     by[i] = by_sim[i]
  #     val[i] = val1[i]
  #   end
  # end

  sumby_contiguous(by, val)
end

"sumby assuming that the elements are organised contiguously; it does not perform a check"
function sumby_contiguous(by_sorted::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S} where {T, S<:Number}
  res = Dict{T,S}()
  @inbounds tmp_val = val[1]
  @inbounds last_byi = by_sorted[1]
  @inbounds for i in 2:length(by_sorted)
    if by_sorted[i] == last_byi
      tmp_val += val[i]
    else
      res[last_byi] = tmp_val
      tmp_val = val[i]
      last_byi = by_sorted[i]
    end
  end

  @inbounds res[last_byi] = tmp_val

  res
end

#sumby_contiguous2 is too slow
# function sumby_contiguous2{T,S}(by_sorted::AbstractVector{T},  val::AbstractVector{S})
#   res = Dict{T,S}()
#   @inbounds last_byi = by_sorted[1]
#   lo = 1
#   hi = 1
#   @inbounds for i in 2:length(by_sorted)
#     if val[i] == last_byi
#       hi += 1
#     else
#       res[last_byi] = sum(val[lo:hi])
#       last_byi = by_sorted[i]
#       lo, hi = hi + 1, hi + 1
#     end
#   end
#
#   @inbounds res[last_byi] = sum(val[lo:hi])
#
#   res
# end

"This is faster for smaller by and also doesn't change the input"
function sumby_sortperm(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S} where {T, S<:Number}
    sp = sortperm(by, alg = RadixSort)
    sumby_contiguous(view(by, sp), view(val,sp))
end
# function sumby_sortperm2{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S}
#     sp = sortperm(by)
#     sumby_contiguous(by[sp], val[sp])
# end

"sumby using Dict - can be quite slow due to slow hash table operations"
function sumby_dict(by::AbstractVector{T}, val::AbstractVector{S})::Dict{T,S} where {T,S<:Number}
  res = Dict{T, S}()
  # resize the Dict to a larger size
  for (byi, vali) in zip(by, val)
    index = ht_keyindex2(res, byi)
    if index > 0
      @inbounds res.vals[index] += vali
    else
      @inbounds _setindex!(res, vali, byi, -index)
    end
  end
  return res
end

#Optimized sumby for PooledArrays
function sumby(by::Union{PooledArray, CategoricalArray}, val::AbstractVector{S}) where {S<:Number}
  l = length(by.pool)
  res = zeros(S, l)
  #refs = Int64.(by.refs)
  refs = by.refs

  for (i, v) in zip(refs, val)
    @inbounds res[i] += v
  end
  return Dict(by.pool[i] => res[i] for i in S(1):S(l))
end

sumby!(dt::Union{AbstractDataFrame, NDSparse}, by::Symbol, val::Symbol) = sumby!(column(dt,by), column(dt,val))
