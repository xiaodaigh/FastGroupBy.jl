using Compat
import Base.Forward

using SortingAlgorithms, Base.Order, Compat, IndexedTables, DataFrames
import Base: ht_keyindex, rehash!, _setindex!
import SortingAlgorithms: uint_mapping, RADIX_SIZE, RADIX_MASK
import DataFrames: DataFrame, AbstractDataFrame
import IndexedTables: IndexedTable, column
import PooledArrays.PooledArray
import CategoricalArrays.CategoricalArray
import SplitApplyCombine.groupreduce

function sumby_radixsort_extra{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S}
  by_sim = similar(by)
  val1=similar(val)
  o = Forward
  lo = 1
  hi = length(by)

  if hi == 0;  return Dict{T,S}();
  elseif hi == 1;  return Dict{T,S}(by[1] => val[1]);  end

  # Make sure we're sorting a bits type
  #TT = Base.Order.ordtype(o, by)
  if !isbits(T)
      error("Radix sort only sorts bits types (got $T)")
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
      tic()
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
      toc()
  end

  sumby_contiguous(by, val)
end
