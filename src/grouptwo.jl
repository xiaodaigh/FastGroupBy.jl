import Base: isbits, sizeof, similar
using SortingAlgorithms
import SortingAlgorithms: RADIX_SIZE, RADIX_MASK
import Base: getindex, setindex!, similar

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

function grouptwo!(byvec::AbstractVector{String}, valvec)
    lens = maximum(sizeof, byvec)
    iters = Int(ceil(lens/sizeof(UInt)))
    sv = FastGroupBy.ValIndexVector(byvec, valvec)
    for i = iters:-1:1
        # compute the bit representation for the next 8 bytes
        bitsrep = load_bits.(UInt, sv.svec, (i-1)*sizeof(UInt))
        grouptwo!(bitsrep, sv)
    end

    return sv
end

################################################################################
# TODO: grouptwo! for categorical types
################################################################################


################################################################################
# grouptwo! for arbitrary types
# TODO: use the fast fsortperm for known types
################################################################################
function grouptwo!(byvec, valvec)
    new_idx = sortperm(byvec)

    newbyvec = byvec[new_idx]
    newvalvec = valvec[new_idx]

    byvec .= newbyvec
    valvec .= newvalvec

    (byvec, valvec)
end

################################################################################
# Defined a structure to allow easier reordering
################################################################################
struct ValIndexVector{T,S}
    svec::Vector{T}
    index::Vector{S}
end

function setindex!(siv::ValIndexVector, X::ValIndexVector, inds)
    siv.svec[inds] = X.svec
    siv.index[inds] = X.index
end

function setindex!(siv::ValIndexVector, X, inds)
    siv.svec[inds] = X[1]
    siv.index[inds] = X[2]
end

getindex(siv::ValIndexVector, inds::Integer) = siv.svec[inds], siv.index[inds]
getindex(siv::ValIndexVector, inds...) = ValIndexVector(siv.svec[inds...], siv.index[inds...])
similar(siv::ValIndexVector) = ValIndexVector(similar(siv.svec), similar(siv.index))
size(siv::ValIndexVector) = length(siv.svec)
