using SortingAlgorithms

function fastby(fns::NTuple{N, Function}, byvec::CategoricalVector, valvec::Tuple) where N
    # TODO generalize for categorical
    # TODO can just copy the code from fastby
    res = fastby(fns, byvec.refs, valvec)
    # (byvec.pool.index[res[1].+1], res[2:length(res)]...)
end

# function fastby2(fns::NTuple{N, Function}, byvec::CategoricalVector, valvec::Tuple) where N
#     # TODO generalize for categorical
#     # TODO can just copy the code from fastby
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
    valvec::AbstractVector{S}, 
    outType::Type{W}= valvec[1:1] |> fn |> typeof) where {S, pooltype, indextype, W}
    l = length(byvec.pool)
   
    # count the number of occurences of each ref
    res = Dict{pooltype, W}()
    if fn == Base.sum
        resvec = zeros(W, l)
        @inbounds for (r,v) in zip(byvec.refs, valvec)
            resvec[r] += v
        end
        @inbounds for (i,c) in enumerate(resvec)
            res[byvec.pool[i]] = c
        end
        # res = Dict{pooltype, W}(byvec.pool[i] => resvec[i] for i in 1:l)
    else
        counter = zeros(UInt, l)
        for r1 in byvec.refs
            @inbounds counter[r1] += 1
        end
        
        lbyvec = length(byvec)
        r1 = byvec.refs[lbyvec]

        # check for degenerate case
        if counter[r1] == lbyvec
            return Dict(byvec[1] => fn(valvec))
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

        for nzpos in nonzeropos
            (po, lo, hi) = (byvec.pool[nzpos], rangelo[nzpos], rangehi[nzpos])
            res[po] = fn(simvalvec[lo:hi])
        end
    end

    return res
end

function cate_sum_by(byvec::Union{PooledArray{pooltype, indextype}, CategoricalArray{pooltype, indextype}}, valvec::AbstractVector{S}, outType::Type{W} = valvec[1:1] |> sum |> typeof) where {S, pooltype, indextype, W}
    l = length(byvec.pool)
    # count the number of occurences of each ref
    res = Dict{pooltype, W}()
    resvec = zeros(S, l)
    @inbounds for (r,v) in zip(byvec.refs, valvec)
        resvec[r] += v
    end
    for (i,c) in enumerate(resvec)
        res[byvec.pool[i]] = c
    end
    res
end