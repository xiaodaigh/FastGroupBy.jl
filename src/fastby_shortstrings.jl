using ShortStrings, SortingLab, FastGroupBy, SortingAlgorithms

import FastGroupBy: _fastby!
function _fastby!(
    fn::Function, 
    byvec::AbstractVector{ShortString{T}}, 
    valvec::AbstractVector{S}, 
    ::Type{outType} = fn(valvec[1:1]) |> typeof) where {T, S, outType}

    # make structure
    bv = collect(zip(byvec, valvec))
    sort!(bv, by = x->x[1].size_content, alg = RadixSort)

    lastby = bv[1][1]
    res = Dict{ShortString{T}, outType}()
    start = 1
    @inbounds for i = 2:length(bv)
        newby = bv[i][1]
        if lastby != newby
            res[lastby] = fn([bv1[2] for bv1 in @view(bv[start:i-1])])
            lastby = newby
            start = i
        end
    end

    res[bv[end][1]] = fn([bv1[2] for bv1 in @view(bv[start:end])])
    res
end



if false
    @time byvec = rand("id".*dec.(1:100,3), 10_000_000) .|> ShortString7;
    @time valvec = rand(length(byvec));
    fn = sum
    T = UInt64
    outType = Float64
    @time _fastby!(sum, byvec, valvec);
    @time fastby(sum, byvec, valvec);

    a = rand([randstring(rand(1:8))  for i = 1:100_000] .|> ShortString15, 10_000_000)
end