# Map a bits-type to an unsigned int, maintaining sort order
using SortingAlgorithms, Base.Order, Compat, IndexedTables
import Base: ht_keyindex, rehash!
import SortingAlgorithms: uint_mapping, RADIX_SIZE, RADIX_MASK
import DataFrames: DataFrame, AbstractDataFrame
import IndexedTables: IndexedTable, column
import PooledArrays.PooledArray
import CategoricalArrays.CategoricalArray

function sumby{T,S}(by::AbstractVector{T},  val::AbstractVector{S})
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

function sumby_sorted{T,S}(by_sorted::AbstractVector{T},  val::AbstractVector{S})
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

# function sumby_sorted2{T,S}(by_sorted::AbstractVector{T},  val::AbstractVector{S})
#   res = Dict{T,S}()
#   @inbounds tmp_val = val[1]
#   @inbounds last_byi = by_sorted[1]
#   @inbounds for i in 2:length(by_sorted)
#     if val[i] == last_byi
#       tmp_val += by_sorted[1]
#     else
#       res[last_byi] = tmp_val
#       tmp_val = val[i]
#       last_byi = by_sorted[i]
#     end
#   end

#   @inbounds res[last_byi] = tmp_val
#
#   res
# end


function sumby_dict{T,S}(by::AbstractArray{T,1}, val::AbstractArray{S,1})
  res = Dict{T, S}()
  # resize the Dict to a larger size
  for (byi, vali) in zip(by, val)
    index = ht_keyindex(res, byi)
    if index > 0
      @inbounds  res.vals[index] += vali
    else
      @inbounds res[byi] = vali
    end
  end
  return res
end

#Optimized sumby for PooledArrays
function sumby{S}(by::Union{PooledArray, CategoricalArray}, val::AbstractArray{S,1})
  l = length(by.pool)
  res = zeros(S, l)
  refs = Int64.(by.refs)

  for (i, v) in zip(refs, val)
    @inbounds res[i] += v
  end
  return Dict(by.pool[i] => res[i] for i in 1:l)
end

sumby(dt::Union{AbstractDataFrame, IndexedTable}, by::Symbol, val::Symbol) = sumby(column(dt,by), column(dt,val))

function psumby{T,S}(by::SharedArray{T,1}, val::SharedArray{S,1})
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

function psumby{S}(by::Union{PooledArray, CategoricalArray}, val::Vector{S})
  return sumby(by, val)
end

function psumby{T,S}(by::Vector{T}, val::Vector{S})
  bys = SharedArray(by)
  vals = SharedArray(val)
  return psumby(bys, vals)
end


psumby(dt::Union{AbstractDataFrame, IndexedTable}, by::Symbol, val::Symbol) = psumby(column(dt,by), column(dt,val))
