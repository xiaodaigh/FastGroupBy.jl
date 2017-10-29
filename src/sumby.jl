#
#  Split - Apply - Combine - sumby operations
#


##############################################################################
##
## sumby...
##
##############################################################################

"""
Perform sum by group
```julia
sumby(df::Union{AbstractDataFrame,IndexedTable}, by::Symbol, val::Symbol)
sumby(by::AbstractVector  val::AbstractVector)
```
### Arguments
* `df` : an AbstractDataFrame/IndexedTable from which to extract the by and val columns
* `by` : data table column to group by
* `val`: data table column to sum
### Returns
* `::Dict` : A Dict that maps unqiues values of by to sum of val

### Examples
```julia
# Generate some data
const N = 10_000_000
const K = 100
srand(1)
@time idt = IndexedTable(
  Columns(row_id = [1:N;]),
  Columns(
    id = rand(1:K,N),
    val = rand(round.(rand(K)*100,4), N)
  ));

# sumby is faster for IndexedTables without nulls
@elapsed IndexedTables.aggregate_vec(sum, idt, by =(:id,), with = :val)
@elapsed sumby(idt, :id, :val)

# sumby is also faster for DataFrame without nulls
@elapsed idtdf = DataFrame(idt)
@elapsed DataFrames.aggregate(idtdf, :id, sum)
@elapsed sumby(idtdf, :id, :val)

# or you can apply directly to vectors
@elapsed sumby(column(idt, :id), column(idt, :val))

```
"""
function sumby{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S})
  by_sim = similar(by)
  val1=similar(val)
  o = Forward
  lo = 1
  hi = length(by)

  if lo >= hi;  return by;  end

  # Make sure we're sorting a bits type
  TT = Base.Order.ordtype(o, by)
  if !isbits(TT)
      error("Radix sort only sorts bits types (got $TT)")
  end

  # Init
  iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE)
  bin = zeros(UInt32, 2^RADIX_SIZE, iters)
  if lo > 1;  bin[1,:] = lo-1;  end

  # Histogram for each element, radix
  for i = lo:hi
      v = uint_mapping(o, by[i])
      for j = 1:iters
          idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
          @inbounds bin[idx,j] += 1
      end
  end

  # Sort!
  swaps = 0
  len = hi-lo+1
  for j = 1:iters
  # Unroll first data iteration, check for degenerate case
    v = uint_mapping(o, by[hi])
    idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1

    # are all values the same at this radix?
    if bin[idx,j] == len;  continue;  end

    cbin = cumsum(bin[:,j])
    ci = cbin[idx]
    by_sim[ci] = by[hi]
    val1[ci] = val[hi]

    cbin[idx] -= 1

    # Finish the loop...
    @inbounds for i in hi-1:-1:lo
        v = uint_mapping(o, by[i])
        idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
        ci = cbin[idx]
        by_sim[ci] = by[i]
        val1[ci] = val[i]
        cbin[idx] -= 1
    end
    by,by_sim = by_sim,by
    val,val1 = val1,val
    swaps += 1
  end

  @inbounds if isodd(swaps)
    by,by_sim = by_sim,by
    val,val1 = val1,val
    for i = lo:hi
        by[i] = by_sim[i]
        val[i] = val1[i]
    end
  end

  sumby_sorted(by, val)
end

function sumby_sorted{T, S<:Number}(by_sorted::AbstractVector{T},  val::AbstractVector{S})
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

#sumby_sorted2 is too slow
# function sumby_sorted2{T,S}(by_sorted::AbstractVector{T},  val::AbstractVector{S})
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


function sumby_dict{T,S<:Number}(by::AbstractVector{T}, val::AbstractVector{S})
  res = Dict{T, S}()
  # resize the Dict to a larger size
  for (byi, vali) in zip(by, val)
    index = ht_keyindex2(res, byi)
    if index > 0
      #@inbounds  res.vals[index] += vali
      res.age += 1
      @inbounds res.keys[index] = byi
      @inbounds res.vals[index] += vali
    else
      # @inbounds res[byi] = vali
      @inbounds _setindex!(res, vali, byi, -index)
    end
  end
  return res
end

#Optimized sumby for PooledArrays
function sumby{S<:Number}(by::Union{PooledArray, CategoricalArray}, val::AbstractVector{S})
  l = length(by.pool)
  res = zeros(S, l)
  #refs = Int64.(by.refs)
  refs = by.refs

  for (i, v) in zip(refs, val)
    @inbounds res[i] += v
  end
  return Dict(by.pool[i] => res[i] for i in S(1):S(l))
end

sumby(dt::Union{AbstractDataFrame, IndexedTable}, by::Symbol, val::Symbol) = sumby(column(dt,by), column(dt,val))

function psumby{T,S<:Number}(by::SharedArray{T,1}, val::SharedArray{S,1})
  np = nprocs()
  if np == 1
    throw(ErrorException("only one proc"))
  end
  l = length(by)
  chunks = sort(collect(Set([1:Int64(round(l/nprocs())):l...,l])))
  ll =length(chunks)
  res = pmap(2:ll) do i
    j = Int64(chunks[i-1]):Int64(chunks[i])
    sumby_dict(by[j], val[j])
  end

  # algorithms to collate all dicts
  fnl_res = res[1]
  szero = zero(S)
  for i = 2:length(res)
    next_res = res[i]
    for k = keys(next_res)
      fnl_res[k] = get(fnl_res, k, szero) + next_res[k]
    end
  end
  fnl_res
end

function psumby{S<:Number}(by::Union{PooledArray, CategoricalArray}, val::Vector{S})
  return sumby(by, val)
end

function psumby{T,S<:Number}(by::Vector{T}, val::Vector{S})
  bys = SharedArray(by)
  vals = SharedArray(val)
  return psumby(bys, vals)
end


psumby(dt::Union{AbstractDataFrame, IndexedTable}, by::Symbol, val::Symbol) = psumby(column(dt,by), column(dt,val))
