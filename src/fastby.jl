"""
Fast Group By algorithm
"""

fastby(fn::Function, byvec, valvec, outType = typeof(fn(valvec[1:1]))) =  fastby!(fn, copy(byvec), copy(valvec), outType)

fastby(fn::Function, byvec, valvec) = length(byvec) == length(valvec) == 0 ? throw(error("length of byvec and valvec can not be 0")) : fastby!(fn, copy(byvec), copy(valvec))

fastby(fn::Function, df::AbstractDataFrame, bycol::Symbol) = fastby(fn, df, bycol, bycol)

function fastby(fn::Function, df::AbstractDataFrame, bycol::Symbol, valcol::Symbol)
    dictres = fastby!(fn, copy(column(df, bycol)), copy(column(df, valcol)))
    DataFrame(bycol = keys(dictres) |> collect, valcol = values(dictres) |> collect)
end

# function fastby(fn::Function, df::AbstractDataFrame, bycol::Symbol, outType = typeof(fn(df[1,:])))
#     # dictres = fastby!(fn, copy(column(df, bycol)), copy(column(df,valcol)))
#     l = size(df,1)
#     row_id = fcollect(l)
#     bycolval = copy(column(df,bycol))
#     grouptwo!(bycolval, row_id)
    
#     last_bycolval = bycolval[1]
#     lo = 1
#     hi = 1
#     res = Dict{eltype(bycolval), outType}()
#     for i = 2:length(bycolval)
#         if last_bycolval != bycolval[i]
#             hi = i - 1
#             res[last_bycolval] = fn(df[lo:hi,:])
#             last_bycolval = bycolval[i]
#             lo = i
#         end
#     end

#     res[bycolval[l]] = fn(df[lo:l])
#     fastby(fn, df, bycol, bycol) 
# end

function fastby(fn::Function, x::Vector{Bool}, y)
    # TODO: fast path for sum and mean
    Dict{Bool, typeof(fn(y[1:1]))}(
        true => fn(@view(y[x])), 
        false => fn(@view(y[.!x])))
end

function fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, outType = typeof(fn(valvec[1:1]))) where {T, S}
    length(byvec) == length(valvec) || throw(DimensionMismatch())
    # if length(byvec) == 0
    #     return Dict{T, outType}()
    # end
    if issorted(byvec)
        h = _contiguousby(fn, byvec, valvec, outType)::Dict{T,outType}
    else
        h = _fastby!(fn, byvec, valvec, outType)::Dict{T,outType}
    end
    return h
end

"""
Internal: single-function fastby
"""
function _fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, outType = typeof(fn(valvec[1:1]))) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S}
    l = length(byvec)
    grouptwo!(byvec, valvec)
    return _contiguousby(fn, byvec, valvec, outType)
end


# import Base.size
"""
fastby! for multiple inputs
"""
function fastby(fn::Function, df::DataFrame, byvec::AbstractVector{Symbol})
    @time indexes = fcollect(size(df,1))
    for bv in reverse(byvec)
        @time grouptwo!(copy(df[bv]), indexes)
    end
    indexes
    # df[indexes,:]
end


"""
Apply by-operation assuming that the vector is grouped i.e. elements that belong to the same group by stored contiguously
"""
function _contiguousby(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, outType = typeof(fn(valvec[1:1]))) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S}
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
Internal multi-function fastby
"""
function _fastby!(fn::Vector{Function}, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T <: BaseRadixSortSafeTypes, S}
    l = length(byvec)
    grouptwo!(byvec, valvec)
    lastby = byvec[1]

    res = Dict{T}()

    j = 1

    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            viewvalvec = @view valvec[j:i-1]
            @inbounds res[lastby] = ((fn1(viewvalvec) for fn1 in fn)...)
            j = i
            @inbounds lastby = byvec[i]
        end
    end

    viewvalvec = @view valvec[j:l]
    @inbounds res[byvec[l]] = ((fn1(viewvalvec) for fn1 in fn)...)
    return res
end


