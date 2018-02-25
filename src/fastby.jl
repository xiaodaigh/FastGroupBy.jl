"""
Fast Group By algorithm
"""

fastby(fn::Function, byvec, valvec) =  length(byvec) == length(valvec) == 0 ? throw(error("length of byvec and valvec can not be 0")) : fastby!(fn, copy(byvec), copy(valvec))

# fastby(fn::Function, byvec, valvec) = length(byvec) == length(valvec) == 0 ? throw(error("length of byvec and valvec can not be 0")) : fastby!(fn, copy(byvec), copy(valvec))

fastby(fn::Function, df::AbstractDataFrame, bycol::Symbol) = fastby(fn, df, bycol, bycol)

function fastby(fn::Function, df::AbstractDataFrame, bycol::Symbol, valcol::Symbol)
    dictres = fastby!(fn, copy(column(df, bycol)), copy(column(df, valcol)))
    DataFrame(bycol = keys(dictres) |> collect, valcol = values(dictres) |> collect)
end

function fastby(fn::Function, x::Vector{Bool}, y)
    # TODO: fast path for sum and mean
    Dict{Bool, typeof(fn(y[1:1]))}(
        true => fn(@view(y[x])), 
        false => fn(@view(y[.!x])))
end

function fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T, S}
    length(byvec) == length(valvec) || throw(DimensionMismatch())
    outType = typeof(fn(valvec[1:1]))
    if issorted(byvec)
        h = _contiguousby(fn, byvec, valvec)::Dict{T,outType}
    else
        h = _fastby!(fn, byvec, valvec)::Dict{T,outType}
    end
    return h
end

"""
Internal: single-function fastby
"""
function _fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S}
    l = length(byvec)
    grouptwo!(byvec, valvec)
    return _contiguousby(fn, byvec, valvec)
end

function fastby(fn::Function, df::DataFrame, byvec::AbstractVector{Symbol}, valsymbol::Symbol)
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

"""
Internal multi-function fastby
"""
function _fastby!(fn::Vector{Function}, byvec::CategoricalVector, valvec::AbstractVector{S}) where {S}
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

# group-by categoricalvector
# multi-function and multi-valvecs
# function fastby(fns::Vector{Function}, byvec::CategoricalVector, valvec::NTuple{2, AbstractVector})
#     # println("wassup")
#     refs = byvec.refs
#     # @time s = SortingLab.fsortperm(refs)

#     # TODO generalise this into another function
#     rangelen = length(byvec.pool)
#     vs = SortingLab.fsortandperm_int_range_lsd(refs, rangelen, 1)
#     s = [Int(vs1.first) for vs1 in vs]
#     refs_grouped = [vs1.second for vs1 in vs]
    
#     # for i = 1:nvec
#     #     FastGroupBy._contiguousby_vec(fns[i], refs_grouped, valvec[i])
#     #     #, FastGroupBy._contiguousby_vec(fns[2], refs_grouped, valvec[2])
#     # end
#     (
#         byvec.pool.index
#         , FastGroupBy._contiguousby_vec(fns[1], refs_grouped, valvec[1][s])[2]
#         , FastGroupBy._contiguousby_vec(fns[2], refs_grouped, valvec[2][s])[2]
#         )
# end

