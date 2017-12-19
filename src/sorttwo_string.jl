function sorttwo_string!(strvec::AbstractVector{S}, sizeofstr = sizeof.(strvec), sim_strvec = similar(strvec)) where {S <: String}
    l = length(strvec)

    # Init
    iters = maximum(sizeofstr)
    bin = zeros(UInt32, 256, iters)

    # Histogram for each element, radix
    @time for i = 1:l
        sz = sizeofstr[i]
        for j = 1:sz
            idx = Int(codeunit(strvec[i], j))+1
            @inbounds bin[idx,j] += 1
        end
        for j = sz+1:iters
            @inbounds bin[1,j] += 1
        end
    end

    # Sort!
    swaps = 0
    for j = iters:-1:1
        # Unroll first data iteration, check for degenerate case
        @inbounds idx = (sizeofstr[l] >= j) ? Int(codeunit(strvec[l], j))+1 : 1

        # are all values the same at this radix?
        if bin[idx,j] == l;  continue;  end

        cbin = cumsum(bin[:,j])
        ci = cbin[idx]
        sim_strvec[ci] = strvec[l]
        cbin[idx] -= 1

        # Finish the loop...
        @inbounds for i in l-1:-1:1
            @inbounds idx = (sizeofstr[i] >= j) ? Int(codeunit(strvec[i], j))+1 : 1

            ci = cbin[idx]
            # println(ci)
            sim_strvec[ci] = strvec[i]
            # println("hello")
            cbin[idx] -= 1
            # println("hello2")
        end
        sim_strvec, strvec = strvec, sim_strvec
        # println("hello3")

        # try
        sizeofstr = sizeof.(strvec)
        swaps += 1
    end

    if isodd(swaps)
        sim_strvec,strvec = strvec,sim_strvec
        for i = 1:l
            @inbounds strvec[i] = sim_strvec[i]
        end
    end
    strvec
end

const M=1000; const K=100
srand(1)
@time svec1 = rand([string(rand(Char.(1:255), rand(1:8))...) for k in 1:M÷K], M)
@time sorttwo_string!(svec1)
issorted(svec1)

function sortone(svec)
    byte = codeunit(svec,1)
end

# test equal length
const M=100_000_000; const K=100
srand(1)
@time svec1 = rand([string(rand(Char.(1:255), rand(1:8))...) for k in 1:M÷K], M)
# @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
@time sorttwo_string!(svec1)
issorted(svec1)

const M=100_000_000; const K=100
srand(1)
@time svec1 = rand([string(rand(Char.(1:255), rand(1:8))...) for k in 1:M÷K], M)

[unsafe_load(Ptr{UInt}(pointer("def")))]

# loading the 8th byte
f(x) = unsafe_load.(pointer.(x) .+ 8)
@time f(svec1) # 3 seconds

f(["def"])

# load all 8 bytes

hh(x) = hhh.(x)
@time hh(svec1)

hhh2(x) = unsafe_load(Ptr{UInt128}(pointer(x))) << (16 - sizeof(x))*8 >> (16-sizeof(x))*8
using BenchmarkTools

hhh(x) = (unsafe_load(Ptr{UInt}(pointer(x))) << (8 - sizeof(x)))*8 >> (8- sizeof(x))*8
hhh3(x) = unsafe_load(Ptr{UInt}(pointer(x)))
hhh4(x) = unsafe_load(Ptr{UInt}(pointer(x))) & UInt(2^sizeof(x)-1)
using BenchmarkTools
@benchmark hhh("abc")
@benchmark hhh3("abc")
@benchmark hhh4("abc")

fh(x) =  unsafe_load.(Ptr{UInt}.(pointer.(x))) # 3 seconds
fh2(x) =  unsafe_load(Ptr{UInt}(pointer(x)))
@time fh(svec1)
@time fh2.(svec1)


function codeunit_check_length(a_str, n)
    if n <= length(a_str)
        return codeunit(a_str,n)
    else
        return 0x00
    end
end

g(x) = codeunit_check_length.(x, 8)
@time g(svec1) # 19 seconds

# @code_warntype sorttwo_string!(svec1)

# srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
# @time radixsort!(svec1)
# issorted(length.(svec1))
# issorted(svec1)

# srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
# @time sort(svec1) # takes about 2 mins for 100m

# srand(1)
# @time svec1 = rand(["id"*dec(k,rand(1:14)) for k in 1:M÷K], M)
# @time radixsort!(svec1)
# issorted(svec1)
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
