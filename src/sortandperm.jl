import Base: isbits, sizeof, ordtype, Ordering
using SortingAlgorithms
import SortingAlgorithms: RadixSortAlg
import SortingAlgorithms: uint_mapping
import SortingAlgorithms: RADIX_SIZE, RADIX_MASK

# const RADIX_SIZE = 20
# const RADIX_MASK = UInt(2^20-1)

function sorttwo!(vs::AbstractVector, index::AbstractVector, lo::Int = 1, hi::Int=length(vs), ::RadixSortAlg=RadixSort, o::Ordering = Base.Forward, ts=similar(vs))
    # Input checking
    if lo >= hi;  return (vs, index);  end

    # Make sure we're sorting a bits type
    T = Base.Order.ordtype(o, vs)
    if !isbits(T)
        error("Radix sort only sorts bits types (got $T)")
    end

    # index = collect(1:hi-lo+1)
    index1 = similar(index)

    # Init
    iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE)
    bin = zeros(UInt32, 2^RADIX_SIZE, iters)
    if lo > 1;  bin[1,:] = lo-1;  end

    # Histogram for each element, radix
    for i = lo:hi
        v = uint_mapping(o, vs[i])
        for j = 1:iters
            idx = Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1
            @inbounds bin[idx,j] += 1
        end
    end

    # Sort!
    swaps = 0
    len = hi-lo+1
    for j = 1:iters
        # Unroll first data iteration, check for degenerate case
        v = uint_mapping(o, vs[hi])
        idx = Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1

        # are all values the same at this radix?
        if bin[idx,j] == len;  continue;  end

        cbin = cumsum(bin[:,j])
        ci = cbin[idx]
        ts[ci] = vs[hi]
        index1[ci] = index[hi]
        cbin[idx] -= 1

        # Finish the loop...
        @inbounds for i in hi-1:-1:lo
            v = uint_mapping(o, vs[i])
            idx = Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1
            ci = cbin[idx]
            ts[ci] = vs[i]
            index1[ci] = index[i]
            cbin[idx] -= 1
        end
        vs,ts = ts,vs
        index, index1 = index1, index
        swaps += 1
    end

    if isodd(swaps)
        vs,ts = ts,vs
        index, index1 = index1, index
        for i = lo:hi
            @inbounds vs[i] = ts[i]
            @inbounds index[i] = index1[i]
        end
    end
    (vs, index)
end


function fsortandperm_radix!(vs::AbstractArray{T})::Tuple{Vector{T}, Vector{Int}} where {T}
    l = length(vs)
    sorttwo!(vs, Array(1:l))
end
