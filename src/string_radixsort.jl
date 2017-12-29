# load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

# function load_bits(::Type{T}, s::String, skipbytes = 0) where T<:Unsigned
#     n = sizeof(s)
#     # if n < skipbytes
#     #     return zero(T)
#     # else
#         ns = (sizeof(T) - min(8, n - skipbytes))*8
#         h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
#         # h = unsafe_load(Ptr{T}(pointer(s)+skipbytes))
#         h = h << ns
#         h = h >> ns
#         return h
#     # end
# end

load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

function load_bits(::Type{T}, s::String, skipbytes = 0) where T
    n = sizeof(s)
    if n < skipbytes
        return zero(T)
    elseif n - skipbytes >= sizeof(T)
        return unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
    else
        ns = (sizeof(T) - min(sizeof(T), n - skipbytes))*8
        h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
        # h = unsafe_load(Ptr{T}(pointer(s)+skipbytes))
        h = h << ns
        h = h >> ns
        return h
    end
end

function load_bits_fast(::Type{T}, s::String,) where T
    n = sizeof(s)   
    ns = (sizeof(T) - n)*8
    h = unsafe_load(Ptr{T}(pointer(s)))
    h = h << ns
    h = h >> ns
    return h
end

function load_bits_fast_ntoh(::Type{T}, s::String,) where T
    n = sizeof(s)   
    ns = (sizeof(T) - n)*8
    h = unsafe_load(Ptr{T}(pointer(s)))
    h = h << ns
    h = h >> ns
    return ntoh(h)
end


function roughhash(s::String)
    n = sizeof(s)
    if n >= 8
        return unsafe_load(Ptr{UInt64}(pointer(s)))
    else
        h = zero(UInt64)
        for i = 1:n
            @inbounds h = (h << 8) | codeunit(s, i)
        end
        return h
    end
end

"""
    radixsort!(vector_string)

Radixsort on strings

    svec - a vector of strings; sorts it by bits
"""
function radixsort_ntoh!(svec::Vector{String}, skipbytes = 0, pointer_type = UInt)
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    iters = ceil(lens*8/SortingAlgorithms.RADIX_SIZE)
    skipbytes = 0
    for i = iters:-1:1
        skipbytes += sizeof(pointer_type)
        x = ntoh.(unsafe_load.(Ptr{pointer_type}.(pointer.(svec) .+ skipbytes)))
        sorttwo!(x, svec)
    end
end


radixsort!(svec::Vector{String}) = radixsort!(UInt, svec::Vector{String})
function radixsort!(::Type{T}, svec::Vector{String}) where T
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    iters = ceil(lens/sizeof(T))
    for i = iters:-1:1        
        sorttwo_lsd16!(load_bits_fast.(T, svec), svec)
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

