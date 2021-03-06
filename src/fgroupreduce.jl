###########################
# Helper functions for 3 or more group-by byvec
###########################

export diffif, diffif!, meanreduce

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
    diff2prev = BitVector(undef, l)
    diff2prev .= false
    diff2prev[1] = true
    @inbounds for i in 1:length(byveccv)
        diffif!(diff2prev, byveccv[i], l)
    end
    diff2prev
end

###########################
# meanreduce
###########################
meanreduce(mean_so_far, new_value, i) = mean_so_far*(i-1)/i + new_value/i

#############################################
# Single groups tuple of fgroupreduce
# Single fn
# Single val
# as long as grouptwo! is defined for byveccv then it's fine
#############################################
"""
    fgroupreduce(fn, byvec, valvec, init)

Group by `byvec` and apply `reduce(fn, valvec, init = init)` within each group
of `byvec`
"""
fgroupreduce(fn, byvec::AbstractVector{T}, valvec::AbstractVector{Z},  init) where {T, Z} = begin
    cm = Dict{T, typeof(fn(init, valvec[1]))}()
    for (b, v) in zip(byvec, valvec)
        index = ht_keyindex2!(cm, b)
        if index > 0
            @inbounds cm.vals[index] = fn(cm.vals[index], v)
        else
            @inbounds Base._setindex!(cm, fn(init, v), b, -index)
        end
    end
    cm
end

#############################################
# Multiple groups tuple of fgroupreduce
# Single fn
# Single val
# as long as grouptwo! is defined for byveccv then it's fine
#############################################
function fgroupreduce!(fn::F, byveccv, val::Vector{Z}, v0 = zero(Z)) where {F<:Function, Z}
    l = length(val)
    # index = collect(1:l)
    lb = length(byveccv)

    # # sort the first column and index
    # @time grouptwo!(byveccv[lb], index)
    #
    # # reorganise value
    # @time @inbounds val .= val[index]
    #
    # # reorganises the other columns
    # @time @inbounds for i = lb-1:-1:1
    #     byveccv[i] .= byveccv[i][index]
    # end

    c1l = collect(1:l)

    # sort the result of the columns
    @time @inbounds for i = lb:-1:2
        println("sorting $i th column")

        index = copy(c1l)

        grouptwo!(byveccv[i], index)
        # for j = lb:-1:i+1
        #     println("    organising $j th column")
        #     byveccv[j] .= byveccv[j][index]
        # end
        for j = i-1:-1:1
            println("    organising $j th column")
            byveccv[j] .= byveccv[j][index]
        end
        println("    organising value")
        val .= val[index]
    end

    println("sorting 1st column and organising value")
    grouptwo!(byveccv[1], val)

    @time diff2prev = diffif(byveccv)
    n_uniques = sum(diff2prev)

    upto = UInt(0)
    res = fill(v0, n_uniques)

    resby = (bv[diff2prev] for bv in byveccv)

    i = 0
    @time @inbounds for (vali, dp) in zip(val, diff2prev)
        #increase upto by 1 if it's different to previous value
        if UInt(dp) == 1
            i = 0
        end
        i += 1
        upto += UInt(dp)
        #res[upto] = fn(res[upto], vali, i)
        res[upto] = fn(res[upto], vali)
    end
    @time (resby..., res)
end

if false
    fn = +
    x = rand(1:1_000, 100_000_000)
    y = rand(1:1_000, 100_000_000)
    byveccv = (x, y)
    val = copy(x)
    v0 = zero(Int)

     fgroupreduce((a, b, _) ->  a + b, byveccv, val)

    Random.seed!(0)
    z = rand(1:1_000_000, 100_000_000)
    val = copy(z)
     fgroupreduce((cum, new, i)-> cum*(i-1)/i + new/i , z, val, 0.0)

     fgroupreduce((a, b, _) ->  a + b, z, val)

    byveccv = (z,)
    fgroupreduce((cum, new, i)-> cum*(i-1)/i + new/i , x, x, 0.0)
end


# if false
#     byveccv = (categorical(df[:id1]).refs, categorical(df[:id2]).refs) .|> copy
#
#     hehe = DataFrame(deepcopy(collect(byveccv)))
#     sort!(hehe, cols=[:x1,:x2])
#
#     fn = +
#     val = df[:v1]
#     T = Int
#     v0 = 0
#
#     byveccv = (rand(1:100,10_000_000), rand(1:100, 10_000_000))
#     val = rand(1:5,10_000_000)
#
#     df[:id10] =
#
#     byveccv1 = (categorical(df[:id1]).refs, categorical(df[:id2]).refs, rand(1:100, 10_000_000)) .|> copy
#
#     @time FastGroupBy.fgroupreduce!(+, byveccv1, val, 0)
#
#     @time FastGroupBy.fgroupreduce(+, byveccv, val, 0)
#
#     @time FastGroupBy.fgroupreduce!(+, byveccv, val, 0)
#     @time FastGroupBy.fgroupreduce2!(+, byveccv, val, 0)
#
#     @time aggregate(df[[:id1, :id2, :v1]], [:id1,:id2], sum)
#
#     @code_warntype fgroupreduce!(+, byveccv, val, 0)
#
#     @time fgroupreduce(+, byveccv, val, 0)
#
#     @time index = fsortperm(byveccv[2])
#
#     @time v2 = byveccv[1][index]
#     @time index = fsortperm(v2)
# end

#############################################
# Multiple groups tuple of fgroupreduce
# Multiple fn
# Multiple val
# as long as grouptwo! is defined for byveccv then it's fine
# TODO: finish this
#############################################
# function fgroupreduce!(fn::NTuple{M, Function}, byveccv::NTuple{N, AbstractVector}, val::NTuple{M, AbstractVector} , v0 = ((zero(eltype(vt)) for vt in val)...)) where {N, M}
#     lenval = length(val[1])
#     index = collect(1:lenval)
#     grouptwo!(byveccv[N], index)
#
#     # reorders the value vectors
#     @time for i = 1:M
#         @inbounds val[i] .= val[i][index]
#     end
#
#     @time for i = N-1:-1:1
#         @inbounds byveccv[i] .= byveccv[i][index]
#     end
#
#     @time @inbounds for i = N-1:-1:1
#         index .= collect(1:lenval)
#         grouptwo!(byveccv[i], index)
#         for j = N:-1:i+1
#             byveccv[j] .= byveccv[j][index]
#         end
#         for j = 1:M
#             val[j] .= val[j][index]
#         end
#     end
#
#     # diff2prev = diffif(byveccv)
#     # n_uniques = sum(diff2prev)
#
#     # upto::UInt = 0
#     # res = fill(v0, n_uniques)
#
#     # res[1] = v0
#     # resby = ((bv[diff2prev] for bv in byveccv)...)
#     # @inbounds for (vali, dp) in zip(val, diff2prev)
#     #     # increase upto by 1 if it's different to previous value
#     #     upto += UInt(dp)
#     #     res[upto] = fn(res[upto], vali)
#     # end
#     # (resby..., res)
# end
#
# function fgroupreduce(fn::NTuple{M, Function}, byveccv::NTuple{N, AbstractVector}, val::NTuple{M, AbstractVector}, v0 = ((zero(eltype(vt)) for vt in val)...)) where {M, N}
#     fgroupreduce!(fn, ((copy(bv) for bv in byveccv)...), ((copy(v) for v in val)...), v0)
# end
#
# if false
#     fn = +
#     byveccv = (df[:id1], df[:id2])
#     M = 3
#     N= 2
#     val = (df[:v1], df[:v2], df[:v3])
#
#     @time fgroupreduce((+,+,+), byveccv, val)
# end

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

########################################
# fgroupreduce for DataFrames
########################################

# only one group by symbol
fgroupreduce(fn, df::AbstractDataFrame, byveccv::Symbol, val::Symbol, v0 = zero(eltype(df[val]))) =
    DataFrame(fgroupreduce(fn, df[!, byveccv], df[!, val], v0) |> collect, [byveccv, val])

# multiple group by symbol
fgroupreduce(fn, df::AbstractDataFrame, bysyms::NTuple{N, Symbol}, val::Symbol) where N =
DataFrame(
    fgroupreduce(
        fn,
        ((df[bs] for bs in bysyms)...),
        df[val]
    ) |> collect
, [bysyms..., val])

# if false
#     a = "id".*dec.(1:100, 3);
#     ar = rand(a, 10_000_00);
#     val = rand(10_000_00);
#     using FastGroupBy
#     @time fastby(sum, ar, val);
#
#     accv = ar |> CategoricalVector
#
#     @time fgroupreduce(+, accv, val)
#
#     using FastGroupBy
#     @time fastby(sum, a, val)
#
#
#     fgroupreduce(sum, df, :)
# end
