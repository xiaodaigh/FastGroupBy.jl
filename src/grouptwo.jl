import Base: isbits, sizeof
using SortingAlgorithms
import SortingAlgorithms: RADIX_SIZE, RADIX_MASK

function grouptwo!(vs::AbstractVector{T}, index) where {T <: BaseRadixSortSafeTypes}
    l = length(vs)
   

    ts = similar(vs)
    index1 = similar(index)

    # Init
    # iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE) # takes 2.954
    
    bits_to_sort = sizeof(T)*8 - leading_zeros(T(reduce(|, vs)))
    iters = ceil(Integer, bits_to_sort/RADIX_SIZE)

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

function grouptwo!(vs::AbstractVector{Bool}, index)
    l = length(vs)

    ts = similar(vs)
    index1 = similar(index)

    # length of trues
    truel = sum(vs)

    # Sort!
    if truel == l
        res = (vs, index)
    else
        falsel = l
        # Finish the loop...
        @inbounds for i in l:-1:1
            if vs[i]
                ts[truel] = vs[i]
                index1[truel] = index[i]
                truel -= 1
            else
                ts[falsel] = vs[i]
                index1[falsel] = index[i]
                falsel -= 1
            end
        end

        for i = 1:l
            @inbounds vs[i] = ts[i]
            @inbounds index[i] = index1[i]
        end

        res = (vs, index)
    end
    return res
end

function grouptwo!(byvec::AbstractVector{String}, valvec, pointer_type = UInt)
    lens = reduce((x,y) -> max(x,sizeof(y)), 0, byvec)
    iters = ceil(lens/sizeof(pointer_type))
    indexes = fcollect(length(byvec))
    for i = iters:-1:1
        # compute the bit representation for the next 8 bytes
        bitsrep = load_bits.(byvec, Int(i-1)*sizeof(pointer_type))
        if i == iters
            grouptwo!(bitsrep, indexes)
        else
            # grouptwo!(@view(bitsrep[indexes]), indexes)
            grouptwo!(bitsrep[indexes], indexes)
        end
    end

    # return (byvec[indexes], valvec[indexes])

    byvec1 = byvec[indexes]
    valvec1 = valvec[indexes]

    for i = 1:length(byvec)
        @inbounds byvec[i] = byvec1[i]
        @inbounds valvec[i] = valvec1[i]
    end
    (byvec, valvec)
end
