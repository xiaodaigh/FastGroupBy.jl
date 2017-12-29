load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

function load_bits(::Type{T}, s::String, skipbytes = 0) where T
    n = sizeof(s)
    # if n < skipbytes
    #     return zero(T)
    # else
        ns = (sizeof(T) - min(sizeof(T), n - skipbytes))*8
        h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
        h = h << ns
        h = h >> ns
        return h
    # end
end

"""
    radixsort!(vector_string)

Radixsort on strings

    svec - a vector of strings; sorts it by bits
"""
radixsort!(svec::Vector{String}) = radixsort!(UInt, svec::Vector{String})

function radixsort!(T, svec::Vector{String})
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    iters = ceil(lens/sizeof(T))
    for i = iters:-1:1
        sorttwo_lsd16!(load_bits.(T, svec, Int(i-1)*sizeof(T)), svec)
    end
end

function radixsort8!(svec::Vector{String})
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    iters = ceil(lens/sizeof(UInt))
    for i = iters:-1:1
        sorttwo_lsd!(load_bits.(svec, Int(i-1)*sizeof(UInt)), svec)
    end
end

"""
use radix to sort the bits but reorder an index instead of the original string
until the very end
"""
function radixsort_index(svec::Vector{String})
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    iters = ceil(lens/sizeof(UInt))
    indexes = fcollect(length(svec))
    for i = iters:-1:1
        # compute the bit representation for the next 8 bytes
        bitsrep = load_bits.(svec, Int(i-1)*sizeof(UInt))
        if i == iters
            sorttwo_lsd16!(bitsrep, indexes)
        else
            sorttwo_lsd16!(@view(bitsrep[indexes]), indexes)
        end
    end
    svec[indexes]
end

