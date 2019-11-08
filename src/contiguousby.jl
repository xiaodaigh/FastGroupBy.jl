# function contiguousby(fn::Vector{Function}, byvec::AbstractVector, valvec::Tuple)
#     # ensure that the number of functions and the number vectors is the same
#     @assert length(fn) == length(valvec)
#     ([FastGroupBy._contiguousby_vec(fn[i], byvec, valvec[i])[2] for i = 1:length(fn)]...)
# end

"""
    _contiguousby(fn, byvec, valvec)

Apply by-operation assuming that the vector is grouped i.e. elements that belong to the same group are stored contiguously
"""
function _contiguousby_dict(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T, S}
    l = length(byvec)
    lastby = byvec[1]
    res = Dict{T,typeof(fn(valvec[1:1]))}()

    j = 1

    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            @inbounds res[lastby] = fn(@view valvec[j:i-1])
            j = i
            @inbounds lastby = byvec[i]
        end
    end

    @inbounds res[byvec[l]] = fn(@view valvec[j:l])
    return res
end

# uses RLE
function _contiguousby_rle(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T, S}
    rleby = rle(byvec)
    lo = 1
    hi = rleby[2][1]
    @inbounds a = fill(fn(@view(valvec[lo:hi])), length(rleby[1]))

    for i in 2:length(rleby[1])
        lo = hi + 1
        @inbounds hi += rleby[2][i]
        println(lo," : ", hi)
        @inbounds a[i] = fn(@view(valvec[lo:hi]))
        # println(lo, hi)
    end
    rleby[1], a
end

"""
    _contiguousreduce(fn, byvec, valvec)

Apply by-operation assuming that the vector is grouped i.e. elements that belong to the same group are stored contiguously
"""
function _contiguousreduce(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, init) where {T, S}
    # l = length(byvec)
    # lastby = byvec[1]
    # res = Dict{T, typeof(fn(valvec[1:1])}()
    #
    # j = 1
    #
    # for i = 2:l
    #     @inbounds byval = byvec[i]
    #     if byval != lastby
    #         @inbounds res[lastby] = fn(viewvalvec)
    #         @inbounds lastby = byvec[i]
    #     end
    # end
    #
    # viewvalvec = @view valvec[j:l]
    # @inbounds res[byvec[l]] = fn(viewvalvec)
    # return res
end

"""
Apply by-operation assuming that the vector is grouped i.e. elements that belong to the same group by stored contiguously
and return a vector
"""
function _contiguousby_vec(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S}
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
    resout = Vector{}(undef, n_uniques)

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
