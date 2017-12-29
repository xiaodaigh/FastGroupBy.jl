"""
Sort the original vector as well as an auxillary index vector in a least
significant digit (lsd) fashion. Good for sortperm implemenations
"""
function sorttwo_lsd16!(vs::AbstractVector{T}, index::AbstractVector{S}) where {T,S}
    l = length(vs)

    ts = similar(vs)
    index1 = similar(index)

    # Init
    iters = sizeof(T) >> 1
    bin = zeros(UInt32, 65536, iters)

    # a function to compute numeric value of two bytes to increment the count with
    function pre_getidx(vsi, j)
        (((vsi >> (j*2-1)*8) & 0xff)) | (((vsi >> (j*2-2)*8) & 0xff) << 8)
    end

    function getidx(vsi, j)
        Int(pre_getidx(vsi,j)) + 1
    end

    # Histogram for each element, radix
    for i = 1:l
        for j = 1:iters
            # idx = Int((vs[i] >> (j-1)*16) & 0xffff) + 1
            idx = getidx(vs[i], j)
            @inbounds bin[idx,j] += 1
        end
    end

    # Sort!
    swaps = 0
    for j = iters:-1:1
        # Unroll first data iteration, check for degenerate case
        idx = getidx(vs[l], j)

        # are all values the same at this radix?
        if bin[idx,j] == l;  continue;  end

        cbin = cumsum(bin[:,j])
        ci = cbin[idx]
        ts[ci] = vs[l]
        index1[ci] = index[l]
        cbin[idx] -= 1

        # Finish the loop...
        @inbounds for i in l-1:-1:1
            idx = getidx(vs[i], j)
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
