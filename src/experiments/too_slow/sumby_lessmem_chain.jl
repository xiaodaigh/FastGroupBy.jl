using FastGroupBy, Compat
import Base.Forward
import SortingAlgorithms: RADIX_MASK, RADIX_SIZE, uint_mapping

"""
sumby that uses much less memory but is slower

It saves memory by not creating a separate copy of by and val vectors but instead
follows a chain of assignment for the swap operations.

"""
function sumby_lessmem_chain{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S})
  o = Forward
  lo = 1
  hi = length(by)

  if lo >= hi;  return by;  end

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
  len = hi-lo+1
  for j = 1:iters
      # Unroll first data iteration, check for degenerate case
      v = uint_mapping(o, by[hi])
      idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1

      # are all values the same at this radix?
      if bin[idx,j] == len;  continue;  end

      cbin = cumsum(bin[:,j])

      # chain assignment to save memory
      touched = BitArray(hi) # to keep track of which cell has been touched
      i = hi
      while i > 0
          begin_index = i # this is where the chain starts
          tmp = (by[i], val[i])
          v = uint_mapping(o, tmp[1])
          idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1

          while true
              ci = cbin[idx]
              new_tmp = (by[ci], val[ci])
              by[ci], val[ci] = tmp[1], tmp[2]
              tmp = new_tmp
              touched[ci] = true # keep track of which number is done
              cbin[idx] -= 1

              if ci == begin_index # the chain has ended
                  break;
              end
              v = uint_mapping(o, tmp[1])
              idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
          end

          while i > 0 && touched[i]
              i -= 1
          end
      end
  end

  sumby_contiguous(by, val)
end
