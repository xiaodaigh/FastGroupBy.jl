"""
Fast Group By algorithm
"""

fastby(fn::Function, byvec, valvec, ::Type{outType} = typeof(fn(valvec[1:1]))) where outType =  length(byvec) == length(valvec) == 0 ? throw(error("length of byvec and valvec can not be 0")) : fastby!(fn, copy(byvec), copy(valvec), outType)

# fastby(fn::Function, byvec, valvec) = length(byvec) == length(valvec) == 0 ? throw(error("length of byvec and valvec can not be 0")) : fastby!(fn, copy(byvec), copy(valvec))

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

function fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, ::Type{outType} = typeof(fn(valvec[1:1]))) where {T, S, outType}
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
function _fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, ::Type{outType} = typeof(fn(valvec[1:1]))) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S, outType}
    l = length(byvec)
    grouptwo!(byvec, valvec)
    return _contiguousby(fn, byvec, valvec, outType)
end


using SortingLab
"""
fastby! for multiple inputs
"""
function fastby1(fn::Function, byvec::Tuple, valvec::AbstractVector)
    l = length(byvec)
    @time indexes = fsortperm(byvec[l])
    @inbounds for i in l-1:1
        @time bv = byvec[i]
        # @time bvv = @view bv[indexes]
        @time bvv = bv[indexes]
        @time indexes1 = fsortperm(bvv)
        @time indexes .= indexes[indexes1]
    end

    byvec_sorted = ([bv[indexes] for bv in byvec]...)
    byvec_sorted
end

function fastby2(fn::Function, byvec::Tuple, valvec::AbstractVector)
    @time indexes = fsortperm(byvec[1].*byvec[2])
    
    byvec_sorted = ([bv[indexes] for bv in byvec]...)
    byvec_sorted
end

function fastby(fn::Function, byvec::Tuple, valvec::AbstractVector)
    l = length(valvec)
    indexes = fcollect(l)
    for i in length(byvec):1
        bv = byvec[i][indexes]
        (tmp, indexes) = grouptwo!(bv, indexes)
    end
    return indexes
    
    # # by now all the groups are done
    # byvec_sorted = ([byvec[i][indexes] for i =1:length(byvec)]...)

    # changed = Vector{Bool}(l - 1)

    
    # valvec = valvec[indexes]

    # lo = 1
    # lastrow = ([a[lo] for a in byvec_sorted]...)

    # cm = Dict{typeof(lastrow), typeof(fn(valvec[1:1]))}()
    # # df1 = DataFrame()
    
    # for i in 2:l
    #     newrow = ([a[i] for a in byvec_sorted]...)
    #     if newrow != lastrow
    #         cm[lastrow] = fn(valvec[lo:i-1])
    #         lo = i
    #         # lastrow = ([a[lo] for a in byvec_sorted]...)
    #         break
    #     end
    # end
    
    # for i in lo:l
    #     newrow = ([a[i] for a in byvec_sorted]...)
    #     if newrow != lastrow
    #         cm[lastrow] = fn(valvec[lo:i-1])
    #         lo = i
    #         # lastrow = ([a[lo] for a in byvec_sorted]...)
    #     end
    # end

    # # cm[lastrow] = fn(valvec[lo:l])
    # cm
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


