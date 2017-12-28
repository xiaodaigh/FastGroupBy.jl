function string_code_unit(s::String, i::Integer)
    if i <= length(s)
        return codeunit(s,i)
    else
        return 0x00
    end
end

function stringsort!(vs::AbstractVector{T}, maxj::Integer = maximum(length.(vs)), j::Integer = 1) where T<:String
    l = length(vs)

    bin = zeros(UInt32, 256)

    # compute the binary code
    indices = string_code_unit.(vs,j) + 1
    for i = 1:l
        idx = indices[i]
        @inbounds bin[idx] += 1
    end

    # Unroll first data iteration, check for degenerate case
    idx = indices[1]

    # are all values the same at this radix?
    if bin[idx] != l
        stringsort!(vs, maxj,  j + 1)
    else
        ts = copy(vs)
        cbin = cumsum(bin)
        cbin_orig_copy = copy(cbin)
        cbin = vcat(0,cbin[1:end-1]) .+ 1

        ci = cbin[idx]
        vs[ci] = ts[1]
        cbin[idx] += 1

        # Finish the loop...
        @inbounds for i in 2:l
            idx = indices[i]
            ci = cbin[idx]
            vs[ci] = ts[i]
            cbin[idx] += 1
        end

        if j < maxj
            for (lo, hi) = zip(vcat(1, cbin_orig_copy[1:end-1] .+ 1), cbin_orig_copy)
                if lo < hi
                    # println(lo,":",hi)
                    stringsort!(view(vs, lo:hi), maxj, j + 1)
                end
            end
        end
    end
    return vs
end

# const M=100_000_000; const K=100
# srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
# #@time svec1 = ["i"*dec(k,rand(1:7)) for k in 1:M÷K]
#
# @time stringsort!(svec1)
# issorted(svec1)
#
# @code_warntype stringsort!(svec1)
#
# x = rand(string.([1:9...]), 10)
# stringsort!(x)
# issorted(x)
