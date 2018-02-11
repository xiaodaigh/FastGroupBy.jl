using ShortStrings, SortingLab, FastGroupBy, SortingAlgorithms

import FastGroupBy: _fastby!
function _fastby!(
    fn::Function, 
    byvec::AbstractVector{ShortString{T}}, 
    valvec::AbstractVector{S}, 
    ::Type{outType} = fn(valvec[1:1]) |> typeof) where {T, S, outType}

    # make structure
    bysc = ShortStrings.size_content.(byvec)
    idx = SortingLab.fsortperm(bysc)
    # sort!(bv, by = x->x[1].size_content, alg = RadixSort)

    byvecv = byvec[idx]
    valvecv = valvec[idx]

    lastby = byvecv[1]
    res = Dict{ShortString{T}, outType}()
    start = 1
    @inbounds for i = 2:length(byvec)
        newby = byvecv[i]
        if lastby != newby
            res[lastby] = fn(@view(valvecv[start:i-1]))
            lastby = newby
            start = i
        end
    end

    res[byvecv[end]] = fn(@view(valvecv[start:end]))
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