"""
Sort the original vector as well as an auxillary index vector in a least
significant digit (lsd) fashion. Good for sortperm implemenations
"""
function sorttwo_lsd!(vs::AbstractVector{T}, index::AbstractVector{S}) where {T,S}
    l = length(vs)

    ts = similar(vs)
    index1 = similar(index)

    # Init
    iters = sizeof(T)
    bin = zeros(UInt32, 256, iters)

    # Histogram for each element, radix
    for i = 1:l
        for j = 1:iters
            idx = Int((vs[i] >> (j-1)*8) & 0xff) + 1
            @inbounds bin[idx,j] += 1
        end
    end

    # function getidx(vsi, j)
    #     Int((vsi >> (j-1)*8) & 0xff) + 1
    # end

    # Sort!
    swaps = 0
    for j = iters:-1:1
        # getidx.(vs,j)
        # Unroll first data iteration, check for degenerate case
        idx = Int((vs[l] >> (j-1)*8) & 0xff) + 1

        # are all values the same at this radix?
        if bin[idx,j] == l;  continue;  end

        cbin = cumsum(bin[:,j])
        ci = cbin[idx]
        ts[ci] = vs[l]
        index1[ci] = index[l]
        cbin[idx] -= 1

        # Finish the loop...
        @inbounds for i in l-1:-1:1
            idx = Int((vs[i] >> (j-1)*8) & 0xff) + 1
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
