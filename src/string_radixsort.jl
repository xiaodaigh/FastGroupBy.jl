load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

function load_bits(::Type{T}, s::String, skipbytes = 0) where T<:Unsigned
    n = sizeof(s)
    ns = n - skipbytes

    h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
    h = (h << (ns)) >>  (ns)

    return h
end

# from https://discourse.julialang.org/t/whats-the-fastest-way-to-generate-1-2-n/7564/15?u=xiaodai
using Base.Threads
function fcollect(N::Integer, T = Int)
    nt = nthreads()
    n,r = divrem(N,nt)
    a = Vector{T}(N)
    @threads for i=1:nt
        ioff = (i-1)*n
        nn = ifelse(i == nt, n+r, n)
        @inbounds for j=1:nn
            a[ioff+j] = ioff+j
        end
    end
    a
end

"""
    radixsort!(vector_string)

Radixsort on strings

    svec - a vector of strings; sorts it by bits
"""
function radixsort!(svec::Vector{String})
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    iters = ceil(lens/sizeof(UInt))
    indexes = fcollect(length(svec))
    for i = iters:-1:1
        sorttwo_lsd16!(load_bits.(svec, Int(i-1)*sizeof(UInt)), svec)
    end
end

function radixsort8!(svec::Vector{String})
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    iters = ceil(lens/sizeof(UInt))
    indexes = fcollect(length(svec))
    for i = iters:-1:1
        sorttwo_lsd!(load_bits.(svec, Int(i-1)*sizeof(UInt)), svec)
    end
end
