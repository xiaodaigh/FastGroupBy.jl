"""
a direct radixsort on strings
    10m - 3-4 seconds slightly slower than radixsort! which only takes 2.5
    100m - 75 seconds
"""
function direct_radixsort_string!(strvec::AbstractVector{S}, sizeofstr = sizeof.(strvec), sim_strvec = similar(strvec)) where {S <: String}
    l = length(strvec)

    # Init
    iters = maximum(sizeofstr)
    bin = zeros(UInt32, 256, iters)

    # Histogram for each element, radix
    @time for i = 1:l
         @inbounds sz = sizeofstr[i]
        for j = 1:sz
            @inbounds idx = Int(codeunit(strvec[i], j))+1
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

# const M=1000; const K=100
# srand(1)
# @time svec1 = rand([string(rand(Char.(1:255), rand(1:8))...) for k in 1:M÷K], M)
# @time radixsort_string!(svec1)
# issorted(svec1)
#
# # test equal length
# const M=10_000_000; const K=100
# srand(1)
# @time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
# # @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
# @time radixsort_string!(svec1) # 3.9 seconds for
# issorted(svec1)
#
# const M=100_000_000; const K=100
# srand(1)
# @time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
# # @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
# @time radixsort_string!(svec1) # 7 seconds for
# issorted(svec1)
