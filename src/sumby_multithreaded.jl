using Base.Threads
function blockranges(nblocks, total_len)
    rem = total_len % nblocks
    main_len = div(total_len, nblocks)

    starts=Int[1]
    ends=Int[]
    for ii in 1:nblocks
        len = main_len
        if rem>0
            len+=1
            rem-=1
        end
        push!(ends, starts[end]+len-1)
        push!(starts, ends[end] + 1)
    end
    @assert ends[end] == total_len
    starts[1:end-1], ends
end

function sumby_multi_rg!(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S} where {T,S <: Number} 
    (starts, ends) = blockranges(nthreads(), length(by))
    res = Dict{T,S}[]
    @threads for (ss, ee) in collect(zip(starts, ends))
        # @inbounds byv = @view by[ss:ee]
        # @inbounds valv = @view val[ss:ee]
        @inbounds push!(res, sumby_radixgroup(by[ss:ee], val[ss:ee]))
    end

    szero  = zero(S)
    @inbounds res_fnl = res[1]
    for res1 in res[2:end]
        for k in keys(res1)
            res_fnl[k] = get(res_fnl,k,szero) + res1[k]
        end
    end
    return res_fnl
end

function sumby_multi_rs!(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S} where {T,S <: Number}
    (starts, ends) = blockranges(nthreads(), length(by))
    res = Dict{T,S}[]
    @threads for (ss, ee) in collect(zip(starts, ends))
        # @inbounds byv = @view by[ss:ee]
        # @inbounds valv = @view val[ss:ee]
        @inbounds push!(res, sumby_radixsort(by[ss:ee], val[ss:ee]))
    end

    szero  = zero(S)
    @inbounds res_fnl = res[1]
    for res1 in res[2:end]
        for k in keys(res1)
            res_fnl[k] = get(res_fnl,k,szero) + res1[k]
        end
    end
    return res_fnl
end

function sumby_multi_van(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S} where {T,S <: Number}
    (starts, ends) = blockranges(nthreads(), length(by))
    res = Dict{T,S}[]
    @threads for (ss, ee) in collect(zip(starts, ends))
        # @inbounds byv = @view by[ss:ee]
        # @inbounds valv = @view val[ss:ee]
        @inbounds push!(res, sumby(by[ss:ee], val[ss:ee]))
    end

    szero  = zero(S)
    @inbounds res_fnl = res[1]
    for res1 in res[2:end]
        for k in keys(res1)
            res_fnl[k] = get(res_fnl,k,szero) + res1[k]
        end
    end
    return res_fnl
end
