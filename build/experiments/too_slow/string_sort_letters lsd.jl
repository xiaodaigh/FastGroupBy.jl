function string_code_unit(s::String, i::Integer)
    if i <= length(s)
        return codeunit(s,i)
    else
        return 0x00
    end
end

function stringsort!(vs::AbstractVector{T}) where T<:String
    l = length(vs)
    ts = similar(vs)

    # Init
    iters = maximum(length.(vs))

    bin = zeros(UInt32, 256, iters)
    # Histogram for each element, radix
    for i = 1:l
        vsi = vs[i]
        for j =1:iters
            idx = string_code_unit(vsi,j) + 1
            @inbounds bin[idx,j] += 1
        end
    end

    # Sort!
    swaps = 0
    for j = iters:-1:1
        # Unroll first data iteration, check for degenerate case
        idx = string_code_unit(vs[l],j) + 1

        # are all values the same at this radix?
        if bin[idx,j] == l;  continue;  end

        cbin = cumsum(bin[:,j])
        ci = cbin[idx]
        ts[ci] = vs[l]
        cbin[idx] -= 1

        # Finish the loop...
        @inbounds for i in l-1:-1:1
            idx = string_code_unit(vs[i],j) + 1
            ci = cbin[idx]
            ts[ci] = vs[i]
            cbin[idx] -= 1
        end
        vs,ts = ts,vs
        print(now())
        swaps += 1
    end

    if isodd(swaps)
        vs,ts = ts,vs
        for i = 1:l
            @inbounds vs[i] = ts[i]
        end
    end
    vs
end



const M=100_000_000; const K=100
srand(1)
@time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
#@time svec1 = ["i"*dec(k,rand(1:7)) for k in 1:M÷K]
@time stringsort!(svec1)
issorted(svec1)

@code_warntype stringsort!(svec1)


sorttwo2!(load_bits.(svec1), svec1)

string_code_unit("id001",6)

length("id001")
