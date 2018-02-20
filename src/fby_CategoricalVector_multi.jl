# what is this fby?
function fby!(fn, byveccv::Tuple{T, S}, val) where {T<:CategoricalVector, S<:CategoricalVector}
    bv1 = byveccv[1]
    bv2 = byveccv[2]
    l1 = length(bv1.pool)
    l2 = length(bv2.pool)
    lv = length(val)

    # make a histogram of unique values
    cnts = zeros(UInt, l2, l1);
    taken = BitArray{2}(l2, l1)
    taken .= false

    @inbounds for i = 1:lv
        j, k = bv2.refs[i], bv1.refs[i]
        cnts[j, k] += 1
        taken[j,k] = true
    end

    num_distinct = sum(taken)

    # create a cumulative count
    firstindex = 0
    
    @inbounds for i = 1:l1
        cnts[:,i] .= cumsum(cnts[:,i]) .+ firstindex
        firstindex = cnts[l2,i]
    end
    
    cbv1 = copy(bv1.refs)
    cbv2 = copy(bv2.refs)
    cval = copy(val)

    @inbounds for k = lv:-1:1
        i, j = cbv2[k], cbv1[k]
        c = cnts[i,j]
        bv1.refs[c] = cbv1[k]
        bv2.refs[c] = cbv2[k]
        val[c] = cval[k]
        cnts[i,j] -= 1
    end

    startindex = 1
    lastbv1 = bv1[1]
    lastbv2 = bv2[2]

    outbv1 = copy(@view(bv1[1:num_distinct]))
    outbv2 = copy(@view(bv2[1:num_distinct]))
    outval = Vector{eltype(fn(val[1:1]))}(num_distinct)

    distinct_encountered = 1
    for k = 2:lv
        if bv1[k] != lastbv1 || bv2[k] != lastbv2
            outbv1[distinct_encountered] = lastbv1
            outbv2[distinct_encountered] = lastbv2
            outval[distinct_encountered] = fn(@view(val[startindex:k-1]))
            lastbv1 =  bv1[k]
            lastbv2 =  bv2[k]
            distinct_encountered += 1
            startindex = k
        end
    end

    outbv1[num_distinct] = lastbv1
    outbv2[num_distinct] = lastbv2
    outval[num_distinct] = fn(@view(val[startindex:lv]))

    (outbv1, outbv2, outval)
end

fby(fn, byveccv::Tuple{T, S}, val) where {T<:CategoricalVector, S<:CategoricalVector} = fby!(fn, (copy(byveccv[1]), copy(byveccv[2])), copy(val))
