load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

function load_bits(::Type{T}, s::String, skipbytes = 0) where T
    n = sizeof(s)
    if n < skipbytes
        return zero(T)
    elseif n - skipbytes >= sizeof(T)
        return ntoh(unsafe_load(Ptr{T}(pointer(s, skipbytes+1))))
    else
        ns = (sizeof(T) - min(sizeof(T), n - skipbytes))*8
        h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
        # h = unsafe_load(Ptr{T}(pointer(s)+skipbytes))
        h = h << ns
        h = h >> ns
        return ntoh(h)
    end
end

"""
    radixsort!(vector_string)

Radixsort on strings

    svec - a vector of strings; sorts it by bits
"""
function radixsort_lsd!(svec::Vector{String})
    # find the maximum string length
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    skipbytes = lens
    while lens > 0
        if lens > 8
            skipbytes = max(0, skipbytes - 16)
            sorttwo!(load_bits.(UInt128, svec, skipbytes), svec)
            lens -= 16
        elseif lens > 4
            skipbytes = max(0, skipbytes - 8)
            sorttwo!(load_bits.(UInt64, svec, skipbytes), svec)
            lens -= 8
        else
            skipbytes = max(0, skipbytes - 4)
            sorttwo!(load_bits.(UInt32, svec, skipbytes), svec)
            lens -= 4
        end
    end
    svec
end

radixsort!(svec::Vector{String}) = radixsort!(UInt, svec::Vector{String})
radixsort!(::Type{T}, svec::Vector{String}) where T = radixsort_lsd!(svec)


# radixsort!(svec::Vector{String}) = radixsort!(UInt, svec::Vector{String})
# function radixsort!(::Type{T}, svec::Vector{String}) where T
#     lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
#     iters = ceil(lens/sizeof(T))
#     for i = iters:-1:1
#         sorttwo!()
#         # sorttwo_lsd16!(load_bits_fast.(T, svec), svec)
#     end
# end

# function radixsort8!(svec::Vector{String})
#     lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
#     iters = ceil(lens/sizeof(UInt))
#     for i = iters:-1:1
#         sorttwo_lsd!(load_bits.(svec, Int(i-1)*sizeof(UInt)), svec)
#     end
# end

# """
# use radix to sort the bits but reorder an index instead of the original string
# until the very end
# """
# function radixsort_index(svec::Vector{String})
#     lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
#     iters = ceil(lens/sizeof(UInt))
#     indexes = fcollect(length(svec))
#     for i = iters:-1:1
#         # compute the bit representation for the next 8 bytes
#         bitsrep = load_bits.(svec, Int(i-1)*sizeof(UInt))
#         if i == iters
#             sorttwo_lsd16!(bitsrep, indexes)
#         else
#             sorttwo_lsd16!(@view(bitsrep[indexes]), indexes)
#         end
#     end
#     svec[indexes]
# end

