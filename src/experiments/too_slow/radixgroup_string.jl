
function radixgroup!(x::Vector{T}, uint::UInt = UInt(1)) where T<:AbstractString
    @time hashindex = hash.(x)
    @time index = collect(1:length(x))
    @time grouptwo!(hashindex, index)
    @time x_permuted = @view x[index]
    @time if isgrouped(x_permuted, hashindex)
        return index
    else
        return radixgroup!(x, uint + 1)
    end
end

function isgrouped(x, hashx)
    x1 = x[1]
    hashx1 = hashx[1]
    for i = 2:length(x)
        @inbounds if x1 != x[i]
            if hashx1 == hashx[i]
                return false
            else
                x1 = x[i]
                hashx1 = hashx[i]
            end
        end
    end
    return true
end

# @time permi = radixgroup!(idstr)


function fastby(fn::Function, byvec::Vector{T}, valvec::Vector) where T <: AbstractString
    permi = radixgroup!(byvec)
    fastby_contiguous(fn, byvec[permi], valvec[permi])
end

function fastby_contiguous(fn::Function, byvec::Vector{T}, valvec::Vector{S}) where {T <: AbstractString, S}
    res = Dict{T, S}()
    l = length(byvec)

    j = 1
    lastby = byvec[1]
    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            viewvalvec = @view valvec[j:i-1]
            @inbounds res[lastby] = fn(viewvalvec)
            j = i
            @inbounds lastby = byvec[i]
        end
    end

    viewvalvec = @view valvec[j:l]
    @inbounds res[byvec[l]] = fn(viewvalvec)
    return res
end

@time fastby(sum, idstr, valvec)

using StatsBase
@time countmap(idstr)
