using SortingAlgorithms

function fastby(fns::NTuple{N, Function}, byvec::CategoricalVector, valvec::Tuple) where N
    # TODO generalize for categorical
    # TODO can just copy the code from fastby
    res = fastby(fns, byvec.refs, valvec)
    # (byvec.pool.index[res[1].+1], res[2:length(res)]...)
end

# function fastby2(fns::NTuple{N, Function}, byvec::CategoricalVector, valvec::Tuple) where N
#     res = fastby2(fns, byvec.refs, valvec)
#     (byvec.pool.index, res...)
# end

# assumes x is sorted, count the number of uniques
function _ndistinct_sorted(f, x)
    lastx = f(x[1])
    cnt = 1
    @inbounds for i = 2:length(x)
        newx = f(x[i])
        if newx != lastx
            cnt += 1
            lastx = newx
        end
    end
    return cnt
end

# multiple one parameter function for one factors
# one byvec
# function fastby(fns::NTuple{N, Function}, byvec::Vector{T}, valvec::NTuple{N, Vector}) where {N, T}
#     println("miao")
#     l = length(byvec)
#     @time abc = collect(zip(byvec,valvec...))
#     @time sort!(abc, by=x->x[1], alg=RadixSort)
    
#     @time ucnt = _ndistinct_sorted(x->x[1], abc)

#     # TODO: return a RLE that is easy to traverse and PARALLELIZE
#     lastby::T = abc[1][1]
#     # res = tuple(Vector{typeof(sum(b[1:1]))}(ucnt), Vector{typeof(mean(c[1:1]))}(ucnt))
#     res = ((Vector{typeof(fn(v[1:1]))}(ucnt) for (fn, v) in zip(fns, valvec))...)
#     u_encountered = 1
#     starti = 1
#     @time @inbounds for i in 2:l
#         newby::T = abc[i][1]
#         if newby != lastby
#             # for k = 1:N
#             #     res[k][u_encountered] = fns[k]([abc[j][1+k] for j=starti:i-1])
#             # end
#             u_encountered += 1
#             starti = i
#             lastby = newby
#         end
#     end
#     for k = 1:N
#         res[k][end] = fns[k]([abc[j][1+k] for j=starti:l])
#     end
#     res
# end

# function fastby2(fns::NTuple{N, Function}, byvec::Vector, valvec::Tuple) where N
#     @time abc = collect(zip(valvec...))
#     l = length(byvec)

#     # A number of alternatives are tested
#     # including sorting sort!(byvec, valvec...)
#     # also sort!(byvec, collect(1:length(byvec))) takes about the same amount of 
#     # time
#     @time FastGroupBy.grouptwo!(byvec, abc)

#     # TODO: now that it returns a RLE, just PARALLELIZE the summation loop
#     @time res1 = FastGroupBy._contiguousby_vec(sum, byvec, repeat([1], inner = length(byvec)))
#     ucnt = length(res1[1])

#     lastby = byvec[1]
#     # res = tuple(Vector{typeof(sum(b[1:1]))}(ucnt), Vector{typeof(mean(c[1:1]))}(ucnt))
#     res = ((Vector{typeof(fn(v[1:1]))}(ucnt) for (fn, v) in zip(fns, valvec))...)
#     u_encountered = 1
#     starti = 1
#     @time @inbounds for i in 2:l
#         newby = byvec[i]
#         if newby != lastby
#             for k = 1:N
#                 res[k][u_encountered] = fns[k]([abc[j][k] for j=starti:i-1])
#             end
#             u_encountered += 1
#             starti = i
#             lastby = newby
#         end
#     end
#     for k = 1:N
#         res[k][end] = fns[k]([abc[j][k] for j=starti:l])
#     end
#     (res1[1], res...)
# end

function fastby4(fns::NTuple{N, Function}, byvec::Vector, valvec::NTuple{N, Vector}) where N
    println("hello")
    @time abc = collect(zip(valvec...))
    l = length(byvec)

    # A number of alternatives are tested
    # including sorting sort!(byvec, valvec...)
    # also sort!(byvec, collect(1:length(byvec))) takes about the same amount of 
    # time
    @time FastGroupBy.grouptwo!(byvec, abc)

    # TODO: now that it returns a RLE, just PARALLELIZE the summation loop
    @time res1 = FastGroupBy._contiguousby_vec(sum, byvec, repeat([1], inner = length(byvec)))
    ucnt = length(res1[1])

    lastby = byvec[1]
    # res = tuple(Vector{typeof(sum(b[1:1]))}(ucnt), Vector{typeof(mean(c[1:1]))}(ucnt))
    res = ((Vector{typeof(fn(v[1:1]))}(ucnt) for (fn, v) in zip(fns, valvec))...)
    u_encountered = 1
    starti = 1
    @time @inbounds for i in 2:l
        newby = byvec[i]
        if newby != lastby
            for k = 1:N
                res[k][u_encountered] = fns[k]([abc[j][k] for j=starti:i-1])
            end
            u_encountered += 1
            starti = i
            lastby = newby
        end
    end
    for k = 1:N
        res[k][end] = fns[k]([abc[j][k] for j=starti:l])
    end
    (res1[1], res...)
end

function fastby(fn::NTuple{N, Function}, byvec::Vector{T}, valvec::NTuple{N, Vector}) where {N, T <: Integer}
    ab = SortingLab.fsortandperm(byvec)
    orderx = ab[2]
    # TODO: make a RLE and parallelize the output
    byby = ab[1]

    # multi-threaded
    res = Vector{Vector}(N+1)
    @threads for j=1:length(valvec)
        vi = valvec[j]
        @inbounds viv = @view(vi[orderx])
        @inbounds res1 = FastGroupBy._contiguousby_vec(fn[j], byby, viv)
        res[j+1] = res1[2]
        if j == 1
            res[1] = res1[1]
        end
    end
    res
end

function fastby!(fn::Function, 
    byvec::Union{PooledArray{pooltype, indextype}, CategoricalVector{pooltype, indextype}},
    # byvec::CategoricalVector{pooltype, indextype}, 
    valvec::AbstractVector{S}
    ) where {S, pooltype, indextype}
    l = length(byvec.pool)
   
    W = valvec[1:1] |> fn |> typeof

    # count the number of occurences of each ref
    # this is the histogram in counting sort
    counter = zeros(UInt, l)
    for r1 in byvec.refs
        @inbounds counter[r1] += 1
    end

    # number of unique groups in the result
    ngrps = sum(counter .!= zero(UInt))
    
    lbyvec = length(byvec)
    r1 = byvec.refs[lbyvec]

    # check for degenerate case where there is only set of values
    if counter[r1] == lbyvec
        return ([byvec[1]], [fn(valvec)])
    end

    uzero = zero(UInt)
    nonzeropos = fcollect(l)[counter .!= uzero]

    counter = cumsum(counter)
    rangelo = vcat(0, counter[1:end-1]) .+ 1
    rangehi = copy(counter)

    simvalvec = similar(valvec)

    ci = counter[r1]
    simvalvec[ci] = valvec[lbyvec]
    counter[r1] -= 1

    @inbounds for i = lbyvec-1:-1:1
        r1 = byvec.refs[i]
        ci = counter[r1]
        simvalvec[ci] = valvec[i]
        counter[r1] -= 1
    end

    # the result group
    resgrp = copy(@view(byvec[1:ngrps]))

    tmpval = fn(valvec)
    resval = fill(tmpval, ngrps)
    i = 1
    for nzpos in nonzeropos
        resgrp.refs[i] = byvec.refs[nzpos]
        (lo, hi) = (rangelo[nzpos], rangehi[nzpos])
        resval[i] = fn(simvalvec[lo:hi])
        i += 1
    end
    
    return (resgrp, resval)
end