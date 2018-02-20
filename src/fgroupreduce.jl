
# tuple of CategoricalArray fgroupreduce
function fgroupreduce(fn, byveccv::Tuple{T, S}, val::Vector{Z}) where {T<:CategoricalVector, S<:CategoricalVector, Z}
    bv1 = byveccv[1]
    bv2 = byveccv[2]
    l1 = length(bv1.pool)
    l2 = length(bv2.pool)
    lv = length(val)

    # make a histogram of unique values
    res = zeros(Z, l2, l1);
    taken = BitArray{2}(l2, l1)
    taken .= false
    @inbounds for i = 1:lv
        j,k = bv2.refs[i], bv1.refs[i]
        res[j,k] = fn(res[j,k], val[i])
        taken[j,k] = true
    end

    num_distinct = sum(taken)

    outbv1 = copy(@view(bv1[1:num_distinct]))
    outbv2 = copy(@view(bv2[1:num_distinct]))
    outval = Vector{Z}(num_distinct)

    distinct_encountered = 1
    @inbounds for i=1:l1
        for j=1:l2
            if taken[j,i]
                outbv1.refs[distinct_encountered] = i
                outbv2.refs[distinct_encountered] = j
                outval[distinct_encountered] = res[j,i]
                distinct_encountered += 1
            end
        end
    end

    (outbv1, outbv2, outval)
end

# group reduce for single categorical
function fgroupreduce(fn, byveccv::CategoricalVector, val::Vector{Z}) where Z
    l1 = length(byveccv.pool)
    lv = length(val)

    # make a histogram of unique values
    res = zeros(Z, l1);
    taken = BitArray(l1)
    taken .= false
    @inbounds for i = 1:lv
        k = byveccv.refs[i]
        res[k] = fn(res[k], val[i])
        taken[k] = true
    end

    num_distinct = sum(taken)

    outbyveccv = copy(@view(byveccv[1:num_distinct]))
    outval = Vector{Z}(num_distinct)

    distinct_encountered = 1
    @inbounds for i=1:l1
        if taken[i]
            outbyveccv.refs[distinct_encountered] = i
            outval[distinct_encountered] = res[i]
            distinct_encountered += 1
        end
    end

    (outbyveccv, outval)
end

fgroupreduce!(fn, byveccv, val) = fgroupreduce(fn, byveccv, val)

# fgroupreduce for DataFrames
fgroupreduce(fn, df, bysyms::Tuple{Symbol, Symbol}, val::Symbol) = DataFrame([fgroupreduce(fn, (df[bysyms[1]], df[bysyms[2]]), df[val])...], [bysyms..., val])

if false
    a = "id".*dec.(1:100, 3);
    ar = rand(a, 100_000_000);
    val = rand(100_000_000);
    using FastGroupBy
    @time fastby(sum, ar, val);

    accv = ar |> CategoricalVector
    
    @time fgroupreduce(+, accv, val)

    using FastGroupBy
    @time fastby(a, val)
end