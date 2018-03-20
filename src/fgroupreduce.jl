###########################
# Helper functions for 3 or more group-by byvec
###########################
function diffif!(difftoprev, vec, l = length(vec))
    lastvec = vec[1]
    @inbounds for i=2:l
        thisvec = vec[i]
        if lastvec != thisvec
            difftoprev[i] = true
            lastvec = thisvec
        end
    end
    difftoprev
end

function diffif(byveccv)
    l = length(byveccv[1])
    diff2prev = BitArray{1}(l)
    diff2prev .= false
    diff2prev[1] = true
    @inbounds for i in 1:length(byveccv)
        diffif!(diff2prev, byveccv[i], l)
    end
    diff2prev
end

#############################################
# Multiple groups tuple of fgroupreduce
# Single fn
# Single val
# as long as grouptwo! is defined for byveccv then it's fine
#############################################
function fgroupreduce!(fn::F, byveccv::Tuple, val::Vector{Z}, v0 = zero(Z)) where {F<:Function, Z}
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

    diff2prev = diffif(byveccv)
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

function fgroupreduce(fn::F, byveccv::Tuple, val::Vector{Z}, v0 = zero(Z)) where {F<:Function, Z}
    fgroupreduce!(fn, ((copy(bv) for bv in byveccv)...), copy(val), v0)
end

if false
    byveccv = (categorical(df[:id1]).refs, categorical(df[:id2]).refs) .|> copy

    hehe = DataFrame(deepcopy(collect(byveccv)))
    sort!(hehe, cols=[:x1,:x2])

    fn = +
    val = df[:v1]
    T = Int
    v0 = 0

    byveccv = (rand(1:100,10_000_000), rand(1:100, 10_000_000))
    val = rand(1:5,10_000_000)

    df[:id10] =

    byveccv1 = (categorical(df[:id1]).refs, categorical(df[:id2]).refs, rand(1:100, 10_000_000)) .|> copy

    @time FastGroupBy.fgroupreduce!(+, byveccv1, val, 0)

    @time FastGroupBy.fgroupreduce(+, byveccv, val, 0)

    @time FastGroupBy.fgroupreduce!(+, byveccv, val, 0)
    @time FastGroupBy.fgroupreduce2!(+, byveccv, val, 0)

    @time aggregate(df[[:id1, :id2, :v1]], [:id1,:id2], sum)

    @code_warntype fgroupreduce!(+, byveccv, val, 0)

    @time fgroupreduce(+, byveccv, val, 0)

    @time index = fsortperm(byveccv[2])

    @time v2 = byveccv[1][index]
    @time index = fsortperm(v2)
end

#############################################
# Multiple groups tuple of fgroupreduce
# Multiple fn
# Multiple val
# as long as grouptwo! is defined for byveccv then it's fine
# TODO: finish this
#############################################
function fgroupreduce!(fn::NTuple{M, Function}, byveccv::NTuple{N, AbstractVector}, val::NTuple{M, AbstractVector} , v0 = ((zero(eltype(vt)) for vt in val)...)) where {N, M}
    lenval = length(val[1])
    index = collect(1:lenval)
    grouptwo!(byveccv[N], index)

    # reorders the value vectors
    @time for i = 1:M
        @inbounds val[i] .= val[i][index]
    end

    @time for i = N-1:-1:1
        @inbounds byveccv[i] .= byveccv[i][index]
    end

    @time @inbounds for i = N-1:-1:1
        index .= collect(1:lenval)
        grouptwo!(byveccv[i], index)
        for j = N:-1:i+1
            byveccv[j] .= byveccv[j][index]
        end
        for j = 1:M
            val[j] .= val[j][index]
        end
    end

    # diff2prev = diffif(byveccv)
    # n_uniques = sum(diff2prev)

    # upto::UInt = 0
    # res = fill(v0, n_uniques)

    # res[1] = v0
    # resby = ((bv[diff2prev] for bv in byveccv)...)
    # @inbounds for (vali, dp) in zip(val, diff2prev)
    #     # increase upto by 1 if it's different to previous value
    #     upto += UInt(dp)
    #     res[upto] = fn(res[upto], vali)
    # end
    # (resby..., res)
end

function fgroupreduce(fn::NTuple{M, Function}, byveccv::NTuple{N, AbstractVector}, val::NTuple{M, AbstractVector}, v0 = ((zero(eltype(vt)) for vt in val)...)) where {M, N}
    fgroupreduce!(fn, ((copy(bv) for bv in byveccv)...), ((copy(v) for v in val)...), v0)
end

if false
    fn = +
    byveccv = (df[:id1], df[:id2])
    M = 3
    N= 2
    val = (df[:v1], df[:v2], df[:v3])

    @time fgroupreduce((+,+,+), byveccv, val)
end

#############################################
# arbitray single
# reduces to fgroupreduce! for multiple tuples but single value vec
#############################################
fgroupreduce!(fn, byvec::AbstractVector, val::Vector{Z}, v0 = zero(Z)) where Z = fgroupreduce!(fn, (byvec,), val, v0)

#############################################
# 2 tuple of CategoricalArray fgroupreduce
#############################################
function fgroupreduce!(fn::F, byveccv::NTuple{2, CategoricalVector}, val::Vector{Z}, v0::T = (fn(val[1], val[1]))) where {F<:Function, Z, T}
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

########################################
# fgroupreduce for single categorical
########################################
function fgroupreduce!(fn::F, byveccv::CategoricalVector, val::Vector{Z}, v0::T = zero(Z)) where {F<:Function, Z,T}
    l1 = length(byveccv.pool)
    lv = length(val)

    # make a histogram of unique values
    res = fill(v0, l1)
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

fgroupreduce(fn, byveccv::AbstractVector, val::Vector{Z}, v0 = zero(Z)) where Z = fgroupreduce!(fn, copy(byveccv), copy(val), v0)

########################################
# fgroupreduce for DataFrames
########################################

# only one group by symbol
fgroupreduce(fn, df::AbstractDataFrame, byveccv::Symbol, val::Symbol, v0 = zero(eltype(df[val]))) =
    DataFrame(fgroupreduce(fn, df[byveccv], df[val], v0) |> collect, [byveccv, val])

# multiple group by symbol
fgroupreduce(fn, df::AbstractDataFrame, bysyms::NTuple{N, Symbol}, val::Symbol) where N =
DataFrame(
    fgroupreduce(
        fn,
        ((df[bs] for bs in bysyms)...),
        df[val]
    ) |> collect
, [bysyms..., val])

if false
    a = "id".*dec.(1:100, 3);
    ar = rand(a, 10_000_00);
    val = rand(10_000_00);
    using FastGroupBy
    @time fastby(sum, ar, val);

    accv = ar |> CategoricalVector

    @time fgroupreduce(+, accv, val)

    using FastGroupBy
    @time fastby(sum, a, val)


    fgroupreduce(sum, df, :)
end
