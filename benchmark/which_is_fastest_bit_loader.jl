load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

function load_bits(::Type{T}, s::String, skipbytes = 0) where T<:Unsigned
    n = sizeof(s)
    # if n < skipbytes
    #     return zero(T)
    # else
        ns = (sizeof(T) - min(8, n - skipbytes))*8
        h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
        # h = unsafe_load(Ptr{T}(pointer(s)+skipbytes))
        h = h << ns
        h = h >> ns
        return h
    # end
end

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

function load_bits_fast(::Type{T}, s::String) where T
    n = sizeof(s)   
    ns = (sizeof(T) - n)*8
    h = unsafe_load(Ptr{T}(pointer(s)))
    h = h << ns
    h = h >> ns
    return h
end

function load_bits_fast_ntoh(::Type{T}, s::String) where T
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
