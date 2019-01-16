"""
Fast Group By algorithm
"""

fastby(fn::Function, byvec, valvec) =  length(byvec) == length(valvec) == 0 ? throw(error("length of byvec and valvec can not be 0")) : fastby!(fn, copy(byvec), copy(valvec))

# fastby(fn::Function, byvec, valvec) = length(byvec) == length(valvec) == 0 ? throw(error("length of byvec and valvec can not be 0")) : fastby!(fn, copy(byvec), copy(valvec))

"""
group by for DataFrame API
"""
fastby(fn::Function, df::AbstractDataFrame, bycol::Symbol) = fastby(fn, df, bycol, bycol)

function fastby(fn::Function, df::AbstractDataFrame, bycol::Symbol, valcol::Symbol)
    res_vec = fastby!(fn, copy(df[bycol]), copy(df[valcol]))
    DataFrame([res_vec...], [bycol, :V1])
    #DataFrame([collect(keys(res_dict)), collect(values(res_dict))], [bycol, :V1])
end

# fastby(fn::NTuple{N, Function}, df::AbstractDataFrame, bycol::Symbol, valcol::NTuple{N,Symbol}) where N =
#     DataFrame(fastby(fn, df[bycol], ((df[vc] for vc in valcol)...)) |> collect, vcat(bycol, valcol...))

function fastby(fn::Function, x::Vector{Bool}, y)
    # TODO: fast path for sum and mean
    ([true, false], [fn(@view(y[x])), fn(@view(y[.!x]))])
end

function fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T, S}
    length(byvec) == length(valvec) || throw(DimensionMismatch())
    outType = typeof(fn(valvec[1:1]))
    if issorted(byvec)
        h = _contiguousby_vec(fn, byvec, valvec)
    else
        h = _fastby!(fn, byvec, valvec)
    end
    return h
end

"""
Internal: single-function fastby, one by, one val
"""
function _fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S}
    # l = length(byvec)
    #grouptwo!(byvec, valvec)    
    SortingLab.sorttwo!(byvec, valvec)
    #return _contiguousby(fn, byvec, valvec)
    return _contiguousby_vec(fn, byvec, valvec)
end

function fastby(fn::Function, df::DataFrame, byvec::Union{AbstractVector{Symbol}, NTuple{N, Symbol}}, valsymbol::Symbol) where N
    indexes = fcollect(size(df,1))
    for bv in reverse(byvec)
        cdfbv = df[bv][indexes]
        grouptwo!(cdfbv, indexes)
    end

    # by now all the groups are done
    dfiv = df[indexes, byvec]
    lo = 1
    lastrow = dfiv[lo,:]
    valvec = df[valsymbol]

    # df1 = DataFrame()
    for i in 2:size(dfiv,1)
        if dfiv[i,:] != lastrow
            lastrow[valsymbol] = fn(valvec[lo:i-1])

            # df1 = lastrow
            lo = i
            lastrow = dfiv[lo,byvec]
            break
        end
    end

    for i in lo:size(dfiv,1)
        if dfiv[i,:] != lastrow
            lastrow[valsymbol] = fn(valvec[lo:i-1])
            # df1 = vcat(df1, lastrow)
            lo = i
            lastrow = dfiv[lo,byvec]
        end
    end

    lastrow[valsymbol] = fn(valvec[lo:size(dfiv,1)])
    lastrow
    # df1 = vcat(df1, lastrow)
    # df1
end

"""
Internal multi-function fastby, one by, one val
"""
# function _fastby!(fn::Union{Vector{Function},NTuple{N, Function}}, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {N, T <: BaseRadixSortSafeTypes, S}
#     l = length(byvec)
#     grouptwo!(byvec, valvec)
#     lastby = byvec[1]
#
#     res = Dict{T}()
#
#     j = 1
#
#     for i = 2:l
#         @inbounds byval = byvec[i]
#         if byval != lastby
#             viewvalvec = @view valvec[j:i-1]
#             @inbounds res[lastby] = ((fn1(viewvalvec) for fn1 in fn)...)
#             j = i
#             @inbounds lastby = byvec[i]
#         end
#     end
#
#     viewvalvec = @view valvec[j:l]
#     @inbounds res[byvec[l]] = ((fn1(viewvalvec) for fn1 in fn)...)
#     return res
# end

"""
Internal multi-function fastby, 1 categorical by, one val
"""
# function _fastby!(fn::Vector{Function}, byvec::CategoricalVector, valvec::AbstractVector{S}) where {S}
#     l = length(byvec)
#     grouptwo!(byvec, valvec)
#     lastby = byvec[1]
#
#     res = Dict{T}()
#
#     j = 1
#
#     for i = 2:l
#         @inbounds byval = byvec[i]
#         if byval != lastby
#             viewvalvec = @view valvec[j:i-1]
#             @inbounds res[lastby] = ((fn1(viewvalvec) for fn1 in fn)...)
#             j = i
#             @inbounds lastby = byvec[i]
#         end
#     end
#
#     viewvalvec = @view valvec[j:l]
#     @inbounds res[byvec[l]] = ((fn1(viewvalvec) for fn1 in fn)...)
#     return res
# end
