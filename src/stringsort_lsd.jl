load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

function load_bits(::Type{T}, s::String, skipbytes = 0) where T<:Unsigned
    n = sizeof(s)
    ns = n - skipbytes

    h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
    h = (h << (ns)) >>  (ns)

    return h

    # if ns >= sizeof(T)
    #     return unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
    # else
    #     # pp = pointer(s)
    #     # for i = n:-1:skipbytes+1
    #     #     @inbounds h = (h << 8) | codeunit(s, i)
    #     #     #hh = (hh << 8) | Base.pointerref(pp, j, 1) # this line is slightly slower but codeunit is preferred as it's documented
    #     # end
    #     h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
    #     h = (h << (ns)) >>  (ns)
    #     return h
    # end
end

function radixsort!(svec::Vector{String})
    lens = maximum(sizeof.(svec))
    iters = ceil(lens/8)
    # sorttwo2!(lens, svec)
    for i = iters:-1:1
        sorttwo2!(load_bits.(svec, Int(i-1)*8),svec)
    end
    # return svec
    # sort the longest vector using LSD

    # skipbytes = 0
    # bitsrep = load_bits.(svec)
    # sorttwo2!(bitsrep, svec)
    # i = 0
    # while !issorted(svec)
    #     i = i + 1
    #     skipbytes += 8
    #     if i == 4
    #         throw(ErrorException("wassup"))
    #     end
    #     sorttwo2!(load_bits.(svec, skipbytes), svec)
    # end
    # return svec
end

# function fast(svec::Vector{String})
#     sorttwo2!(unsafe_load.(Ptr{UInt}.(pointer.(svec))),svec)
#     svec
# end

include("sorttwo2.jl")
const M=1000; const K=100
srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
@time radixsort!(svec1)
issorted(svec1)

const M=100_000_000; const K=100
srand(1)
# @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
# @time fast(svec1)
@time radixsort!(svec1)
@code_warntype radixsort!(svec1)
issorted(svec1)



srand(1)
@time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
@time radixsort!(svec1)
issorted(length.(svec1))
issorted(svec1)

# srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
# @time sort(svec1) # takes about 2 mins for 100m

srand(1)
# @time svec1 = rand(["id"*dec(k,rand(1:14)) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:16))...) for k in 1:M÷K], M)
@time radixsort!(svec1)
issorted(svec1)
#
# srand(1)
# @time svec1 = rand(["id"*dec(k,22) for k in 1:M÷K], M)
# @time radixsort!(svec1)
# issorted(svec1)
#
# x = svec1[1:end-1] .> svec1[2:end]
# x = vcat(false, x) .| vcat(x, false)
# (1:length(x))[x]
#
# svec1[9999248:9999249]
#
#
#
# @time svec1 = rand(["id"*dec(k,rand(1:24)) for k in 1:M÷K], M)
# #@time svec1 = ["id"*dec(k,rand(1:22)) for k in 1:M÷K]
# @time sort!(svec1)
# issorted(svec1)


@time cc = load_bits.(svec1)
@time sort(cc)
include("sorttwo2.jl")
@time sorttwo2!(cc, svec1)

include("sorttwo2.jl")
const M=100_000_000; const K=100
srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
@time lens = maximum(sizeof.(svec1)) # 3-5 econds
iters = ceil(lens/8)
@time cc = load_bits.(svec1) # 9 seconds
ii = [1:length(cc)...]
# @time sorttwo2!(cc, svec1) # 11 seconds
@time sorttwo2!(cc, ii) ## 5 seconds

@time svec1 = svec1[ii]
issorted(svec1)

# return svec
# sort the longest vector using LSD

# skipbytes = 0
# bitsrep = load_bits.(svec)
# sorttwo2!(bitsrep, svec)
# i = 0
# while !issorted(svec)
#     i = i + 1
#     skipbytes += 8
#     if i == 4
#         throw(ErrorException("wassup"))
#     end
#     sorttwo2!(load_bits.(svec, skipbytes), svec)
# end
# return svec
