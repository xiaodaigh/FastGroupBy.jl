load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

function load_bits(::Type{T}, s::String, skipbytes = 0) where T<:Unsigned
    n = sizeof(s)
    if n - skipbytes >= sizeof(T)
        # println("abc1")
        return unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
    else
        # println("abc")
        h = zero(T)
        #pp = pointer(s)
        for i = n:-1:skipbytes+1
            @inbounds h = (h << 8) | codeunit(s, i)
            #hh = (hh << 8) | Base.pointerref(pp, j, 1) # this line is slightly slower but codeunit is preferred as it's documented
        end
        return h
    end
end

function radixsort!(svec::Vector{String})
    bitsrep = load_bits.(svec)
    sorttwo2!(bitsrep, svec)
    svec
end
