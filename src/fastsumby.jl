using Compat
import Base: Forward
import SortingAlgorithms: RADIX_MASK, RADIX_SIZE, uint_mapping
#using FastGroupBy
using BenchmarkTools

using SortingAlgorithms, Base.Order, Compat, IndexedTables, DataFrames
import Base: ht_keyindex, rehash!, _setindex!, ht_keyindex2
import SortingAlgorithms: uint_mapping, RADIX_SIZE, RADIX_MASK
import DataFrames: DataFrame, AbstractDataFrame
import IndexedTables: IndexedTable, column
import PooledArrays.PooledArray
import CategoricalArrays.CategoricalArray
import SplitApplyCombine.groupreduce

using StatsBase

include("C:/Users/L098905/Git/FastGroupBy.jl/src/sumby.jl")

by = nothing
val = nothing
gc()
by = rand(Int8(1):Int8(100), 2_000_000)
val = Int32.(similar(by))
T = Int

function fastsumby{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S}; j = 1)::Dict{T,S}
  by_sim = similar(by)
  val1 = similar(val)
  hi = length(by)
  #if lo >= hi;  return Dict{T,S}(by[1] => sum(val));  end
  if hi == 1;  return Dict{T,S}(by[1] => val[1]);  end
  o = Forward
  lo = 1

  # Make sure we're sorting a bits type
  #TT = Base.Order.ordtype(o, by)
  if !isbits(T)
    error("Radix sort only sorts bits types (got $T)")
  end

  # Init
  bin1 = zeros(UInt32, 2^RADIX_SIZE) # just one bin for the initial run

  # Histogram for each element, radix
  for i = lo:hi
    v = uint_mapping(o, by[i])
    # perform counting then sort them
    idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
    @inbounds bin1[idx] += 1
  end
  # swaps  = 0
  #len = hi-lo+1
  v = uint_mapping(o, by[hi])
  idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1

  # are all values the same at this radix?
  if bin1[idx] == hi
    println(by[1])
    return Dict{T,S}(by[1] => sum(val))
  end

  cbin = cumsum(bin1)
  non_empty_cnt = Int.(cbin[vcat(cbin[1] != 0, diff(cbin) .!= 0)])

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

  iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE)
  if iters == j
    #println(countmap(by_sim))
    return sumby_contiguous(by_sim, val1)
  else
    indices = vcat([1:non_empty_cnt[1]],
      [(a+1):b for (a,b) in zip(non_empty_cnt[1:end-1], non_empty_cnt[2:end])]
      )
    return mapreduce(merge, indices) do ii
      fastsumby(view(by_sim,ii), view(val1,ii); j = j + 1)
    end
  end
end

function abc()
  by1, val1 = copy(by), copy(val)
  @elapsed fastsumby(by1, val1)
end

function def()
  by1, val1 = copy(by), copy(val)
  @elapsed sumby(by1, val1)
end

a1 = mean([abc() for i = 1:5][2:end])
b1 = mean([def() for i = 1:5][2:end])
1 - a1/b1
print()
print()


#
#
# by,by_sim = by_sim,by
# val,val1 = val1,val
# swaps += 1
#
#
#
# # Sort!
# swaps = 0
# len = hi-lo+1
# for j = 1:iters
# # Unroll first data iteration, check for degenerate case
#   v = uint_mapping(o, by[hi])
#   idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
#
#   # are all values the same at this radix?
#   if bin[idx,j] == len;  continue;  end
#
#   cbin = cumsum(bin[:,j])
#   ci = cbin[idx]
#   by_sim[ci] = by[hi]
#   val1[ci] = val[hi]
#
#   cbin[idx] -= 1
#
#   # Finish the loop...
#   @inbounds for i in hi-1:-1:lo
#       v = uint_mapping(o, by[i])
#       idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
#       ci = cbin[idx]
#       by_sim[ci] = by[i]
#       val1[ci] = val[i]
#       cbin[idx] -= 1
#   end
#   by,by_sim = by_sim,by
#   val,val1 = val1,val
#   swaps += 1
# end
#
# @inbounds if isodd(swaps)
#   by,by_sim = by_sim,by
#   val,val1 = val1,val
#   for i = lo:hi
#       by[i] = by_sim[i]
#       val[i] = val1[i]
#   end
# end
#
# sumby_contiguous(by, val)
# #end
