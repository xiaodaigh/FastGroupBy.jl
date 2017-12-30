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
radixsort_lsd!(x) = radixsort_lsd24!(x)

function radixsort_lsd16!(svec::Vector{String})
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

function radixsort_lsd24!(svec::Vector{String})
    # find the maximum string length
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    skipbytes = lens
    while lens > 0
        if lens > 16 && ceil(lens/24) < ceil(lens/16)
            skipbytes = max(0, skipbytes - 24)
            sorttwo!(load_bits.(Bits192, svec, skipbytes), svec)
            lens -= 24
        elseif lens > 8
        # if lens > 8
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

function radixsort_lsd32!(svec::Vector{String})
    # find the maximum string length
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    skipbytes = lens
    while lens > 0
        if lens > 24
            skipbytes = max(0, skipbytes - 32)
            sorttwo!(load_bits.(Bits256, svec, skipbytes), svec)
            lens -= 32
        elseif lens > 16 && ceil(lens/24) < ceil(lens/16)
            skipbytes = max(0, skipbytes - 24)
            sorttwo!(load_bits.(Bits192, svec, skipbytes), svec)
            lens -= 24
        elseif lens > 8
        # if lens > 8
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