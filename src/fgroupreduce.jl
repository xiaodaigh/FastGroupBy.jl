# tuple of CategoricalArray fgroupreduce
# function fgroupreduce(fn::F, byveccv::NTuple{N, CategoricalVector}, val::Vector{Z}) where {Z, N, F<:Function}
#     lcv = (x->x.pool |> length).(byveccv)
#     lv = length(val)
#     # make a histogram of unique values
#     res = zeros(fn(val[1], val[1]) |> typeof, lcv...);
#     taken = BitArray{N}(lcv...)
#     taken .= false
#     @time @inbounds for i = 1:lv
#         idx = (byveccv[j].refs[i] for j=1:N)
#         res[idx...] = fn(res[idx...], val[i])
#         taken[idx...] = true
#     end

#     num_distinct = sum(taken)
#     println(num_distinct)

#     # outbv1 = copy(@view(bv1[1:num_distinct]))
#     # outbv2 = copy(@view(bv2[1:num_distinct]))
#     # outval = Vector{Z}(num_distinct)

#     outres = ((copy(@view(bv[1:num_distinct])) for bv in byveccv)...)
#     outval = Vector{fn(val[1], val[1]) |> typeof}(num_distinct)
#     distinct_encountered = 1

#     @time @inbounds for ijk in zip((1:to for to in size(res))...)
#         if taken[ijk...]
#             for i in 1:length(ijk)
#                 outres[i].refs[distinct_encountered] = ijk[i]
#             end
#             outval[distinct_encountered] = res[ijk...]
#             distinct_encountered += 1
#         end
#     end

#     (outres..., outval)
# end

###########################
# 3 or more group-by byvec
###########################
function da3(vec, l = length(vec))
    difftoprev = BitArray{1}(l)
    difftoprev .= false
    difftoprev[1] = true
    lastvec = vec[1]
    @inbounds for i=2:l
        thisvec = vec[i]
        if lastvec != thisvec
            difftoprev[i-1] = true
            lastvec = thisvec
        end
    end
    difftoprev
end

function da(byveccv)
    l = length(byveccv[1])
    diff2prev = BitArray{1}(l)
    diff2prev .= false
    diff2prev[1] = true
    @inbounds for i in 1:length(byveccv)
        diff2prev .= diff2prev .| da3(byveccv[i], l)
    end
    diff2prev
end



if false
    sort!(df, cols=[:id1,:id2])
    byveccv = (categorical(df[:id1]).refs, categorical(df[:id2]).refs) .|> copy

    hehe = DataFrame(deepcopy(collect(byveccv)))
    sort!(hehe, cols=[:x1,:x2])

    @time a1 = da1(byveccv[1]);
    @time a2 = da2(byveccv[1]);
    @time a3 = da3(byveccv[1]);

    @code_warntype da3(byveccv[2])

    @code_warntype da(byveccv)

    all(a1 .== a2)
    all(a1 .== a3)
    @time da(byveccv) |> sum
    @code_warntype da(byveccv)

    fn = +
    val = df[:v1]
    T = Int
    v0 = 0

    @time FastGroupBy.fgroupreduce!(+, byveccv, val, 0)
    @time FastGroupBy.fgroupreduce2!(+, byveccv, val, 0)

    @time aggregate(df[[:id1,:id2, :v1]], [:id1,:id2], sum)

    @code_warntype fgroupreduce!(+, byveccv, val, 0)

    @time fgroupreduce(+, byveccv, val, 0)

    @time index = fsortperm(byveccv[2])

    @time v2 = byveccv[1][index]
    @time index = fsortperm(v2)
end


function fgroupreduce!(fn::F, byveccv::Tuple, val::Vector{Z}, v0::T = zero(T)) where {F<:Function, Z, T}
    l = length(val)
    index = collect(1:l)
    lb = length(byveccv)
    grouptwo!(byveccv[lb], index)
    @inbounds val .= val[index]
    
    @inbounds for i = lb-1:-1:1
        byveccv[i] .= byveccv[i][index]
    end

    @inbounds for i = lb-1:-1:1
        index .= collect(1:l)
        grouptwo!(byveccv[i], index)
        for j = lb:-1:i+1
            byveccv[j] .= byveccv[j][index]
        end
        val .= val[index]
    end

    diff2prev = da(byveccv)
    n_uniques = sum(diff2prev)

    upto::UInt = 0
    res = fill(v0, n_uniques)

    res[1] = v0
    resby = ((bv[diff2prev] for bv in byveccv)...)
    @inbounds for (vali, dp) in zip(val, diff2prev)
        # increase upto by 1 if it's different to previous value
        upto += UInt(dp)
        res[upto] = fn(res[upto], vali)
    end
    (resby..., res)
end

function fgroupreduce2!(fn::F, byveccv::Tuple, val::Vector{Z}, v0::T = zero(T)) where {F<:Function, Z, T}
    l = length(val)
    index = collect(1:l)
    lb = length(byveccv)
    grouptwo!(byveccv[lb], index)
    @inbounds val .= val[index]
    
    @time @inbounds for i = lb-1:-1:1
        byveccv[i] .= byveccv[i][index]
    end

    @time @inbounds for i = lb-1:-1:1
        index .= collect(1:l)
        grouptwo!(byveccv[i], index)
        for j = lb:-1:i+1
            byveccv[j] .= byveccv[j][index]
        end
        val .= val[index]
    end

    diff2prev = da(byveccv)
    n_uniques = sum(diff2prev)

    upto::UInt = 0
    res = fill(v0, n_uniques)

    res[1] = v0
    resby = ((bv[diff2prev] for bv in byveccv)...)
    @inbounds for (vali, dp) in zip(val, diff2prev)
        # increase upto by 1 if it's different to previous value
        upto += UInt(dp)
        res[upto] = fn(res[upto], vali)
    end
    (resby..., res)
end


# tuple of CategoricalArray fgroupreduce
function fgroupreduce(fn::F, byveccv::NTuple{2, CategoricalVector}, val::Vector{Z}, v0::T = (fn(val[1], val[1]))) where {F<:Function, Z, T}
    bv1 = byveccv[1]
    bv2 = byveccv[2]
    l1 = length(bv1.pool)
    l2 = length(bv2.pool)
    lv = length(val)

    # make a histogram of unique values
    res = fill(v0, (l2, l1))
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
function fgroupreduce(fn::F, byveccv::CategoricalVector, val::Vector{Z}, v0::T = fn(val[1], val[1])) where {F<:Function, Z,T}
    l1 = length(byveccv.pool)
    lv = length(val)

    # make a histogram of unique values
    res = zeros(T, l1);
    taken = BitArray(l1)
    taken .= false
    @inbounds for i = 1:lv
        k = byveccv.refs[i]
        res[k] = fn(res[k], val[i])
        taken[k] = true
    end

    num_distinct = sum(taken)

    outbyveccv = copy(@view(byveccv[1:num_distinct]))
    outval = Vector{T}(num_distinct)

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