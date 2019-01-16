# function contiguousby(fn::Vector{Function}, byvec::AbstractVector, valvec::Tuple)
#     # ensure that the number of functions and the number vectors is the same
#     @assert length(fn) == length(valvec)
#     ([FastGroupBy._contiguousby_vec(fn[i], byvec, valvec[i])[2] for i = 1:length(fn)]...)
# end

"""
Apply by-operation assuming that the vector is grouped i.e. elements that belong to the same group by stored contiguously
"""
function _contiguousby(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, ::Type{outType} = typeof(fn(valvec[1:1]))) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S, outType}
    l = length(byvec)
    lastby = byvec[1]
    res = Dict{T,outType}()

    j = 1

    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            viewvalvec = @view valvec[j:i-1]
            try
                @inbounds res[lastby] = fn(viewvalvec)
            catch e
                @show fn(viewvalvec)
            end
            j = i
            @inbounds lastby = byvec[i]
        end
    end

    viewvalvec = @view valvec[j:l]
    @inbounds res[byvec[l]] = fn(viewvalvec)
    return res
end

"""
Apply by-operation assuming that the vector is grouped i.e. elements that belong to the same group by stored contiguously
and return a vector
"""
function _contiguousby_vec(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, ::Type{outType} = typeof(fn(valvec[1:1]))) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S, outType}
    l = length(byvec)

    lastby = byvec[1]
    n_uniques = 0
    # count n of uniques
    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            n_uniques += 1
            lastby = byval
        end
    end
    n_uniques += 1

    resby = Vector{T}(undef, n_uniques)
    resout = Vector{outType}(undef, n_uniques)

    lastby = byvec[1]
    j = 1
    outrow = 1
    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            viewvalvec = @view valvec[j:i-1]
            @inbounds resby[outrow] = lastby
            @inbounds resout[outrow] = fn(viewvalvec)
            outrow += 1
            j = i
            @inbounds lastby = byval
        end
    end

    viewvalvec = @view valvec[j:l]
    @inbounds resby[end] = byvec[end]
    @inbounds resout[end] = fn(viewvalvec)
    return resby, resout
end
