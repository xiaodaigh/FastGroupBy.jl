import Base: isbits, sizeof
using SortingAlgorithms
import SortingAlgorithms: RADIX_SIZE, RADIX_MASK

# const RADIX_SIZE = 20
# const RADIX_MASK = UInt(2^20-1)

function grouptwo!(vs::AbstractVector{T}, index::AbstractVector{S}) where {T,S<:Number}
    l = length(vs)
    if !isbits(T)
        error("Radix sort only sorts bits types (got $T)")
    end

    ts = similar(vs)
    index1 = similar(index)

    # Init
    iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE)
    bin = zeros(UInt32, 2^RADIX_SIZE, iters)

    # Histogram for each element, radix
    for i = 1:l
        for j = 1:iters
            idx = Int((vs[i] >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1
            @inbounds bin[idx,j] += 1
        end
    end

    # Sort!
    swaps = 0
    for j = 1:iters
        # Unroll first data iteration, check for degenerate case
        idx = Int((vs[l] >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1

        # are all values the same at this radix?
        if bin[idx,j] == l;  continue;  end

        cbin = cumsum(bin[:,j])
        ci = cbin[idx]
        ts[ci] = vs[l]
        index1[ci] = index[l]
        cbin[idx] -= 1

        # Finish the loop...
        @inbounds for i in l-1:-1:1
            idx = Int((vs[i] >> (j-1)*RADIX_SIZE) & RADIX_MASK) + 1
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
        for i = 1:l
            @inbounds vs[i] = ts[i]
            @inbounds index[i] = index1[i]
        end
    end
    (vs, index)
end
