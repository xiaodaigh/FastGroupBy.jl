# function sumby_sortperm2{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S}
#     sp = sortperm(by)
#     sumby_contiguous(by[sp], val[sp])
# end

"This is faster for smaller by and also doesn't change the input"
function sumby_sortperm{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S})::Dict{T,S}
    sp = sortperm(by)
    sumby_contiguous(view(by, sp), view(val,sp))
end
