using Compat, FastGroupBy
import Base: Forward
import SortingAlgorithms: RADIX_MASK, RADIX_SIZE, uint_mapping
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

const N = 1_000_000
const K = 100
by = rand(Int32(1):Int32(N/K), N);
val = similar(by);
T = Int

using DataStructures

# define a heap that invovles the byval and S
struct ByVal{T<:Integer, S <: Number}
    index::Integer
    by::T
    val::S
end

import Base.isless
isless(x::ByVal,y::ByVal) = x.index < y.index

"WAAAAAAAYYY too slow uses less memory by building a heap"
function sumby_lessmem_heap{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S}
    o = Forward
    lo = 1
    hi = length(by)

    if lo >= hi;  return by;  end

    # Make sure we're sorting a bits type
    if !isbits(T)
      error("the by vector must be of bits types (e.g. Float64, Integer) got $T")
    end

    # Init
    iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE)
    bin = zeros(UInt32, 2^RADIX_SIZE, iters)

    # Histogram for each element, radix
    for i = lo:hi
        v = uint_mapping(o, by[i])
        for j = 1:iters
            idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
            @inbounds bin[idx,j] += 1
        end
    end

    # Sort!
    len = hi-lo+1
    for j = 1:iters
        # Unroll first data iteration, check for degenerate case
        v = uint_mapping(o, by[hi])
        idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1

        # are all values the same at this radix?
        if bin[idx,j] == len;  continue;  end

        cbin = cumsum(bin[:,j])
        ci = cbin[idx]

        # ByValHeap -- keeps the data in a heap
        bvheap = binary_maxheap(ByVal)

        # if ci == hi then do nothing
        if ci < hi
          push!(bvheap, ByVal(ci, by[ci], val[ci]))
          by[ci] = by[hi]
          val[ci] = val[hi]
        end
        cbin[idx] -= 1

        loopto = lo-1
        i = hi - 1 # i is used to keep track of where we are up to

        # Finish the loop...
        #   @inbounds for i in hi-1:-1:lo
        while i > 0
          if isempty(bvheap)
              loopto = lo-1
          else
              loopto = top(bvheap).index
          end
          while i > loopto
              v = uint_mapping(o, by[i])
              idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
              ci = cbin[idx]
              if ci > i # it's ok to just put it in place
                  by[ci] = by[i]
                  val[ci] = val[i]
              elseif ci < i # keep the value in a heap for retrieval
                  push!(bvheap, ByVal(ci, by[ci], val[ci]))
                  by[ci] = by[i]
                  val[ci] = val[i]
                  # make the loop end sooner
                  if ci > loopto; loopto = ci; end
              end

              cbin[idx] -= 1
              i -= 1
          end
          # if it got here without being 0 then it must be up to a heap value
          if i != 0
              tmp = pop!(bvheap)
              v = uint_mapping(o, tmp.by)
              idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
              ci = cbin[idx]
              if ci > i # it's ok to just put it in place
                  by[ci] = tmp.by
                  val[ci] = tmp.val
              elseif ci < i # keep the value in a heap for retrieval
                  push!(bvheap, ByVal(ci, by[ci], val[ci]))
                  by[ci] = tmp.by
                  val[ci] = tmp.val
              end

              cbin[idx] -= 1
              i -= 1
          end
        end
    end

    sumby_contiguous(by, val)
end

sumby_lessmem_heap([1:10...],[1:10]

function abc()
  by1, val1 = copy(by), copy(val)
  @elapsed sumby_lessmem_heap(by1, val1)
end

function def()
  by1, val1 = copy(by), copy(val)
  @elapsed sumby(by1, val1)
end

a1 = mean([abc() for i = 1:5][2:end])
b1 = mean([def() for i = 1:5][2:end])
1 - a1/b1

function ghi()
  by1, val1 = copy(by), copy(val)
  @elapsed sumby_lessmem_chain(by1, val1)
end
c1 = mean([ghi() for i = 1:5][2:end])
1 - c1/b1
