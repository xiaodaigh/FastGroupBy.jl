function meanby{S,T}(id4::AbstractArray{T,1}, v1::AbstractArray{S,1})
  res = Dict{T, Tuple{S, Int64}}()
  szero = zero(S)
  for (id, val) in zip(id4,v1)
    index = ht_keyindex(res, id)
    if index > 0
      @inbounds vw = res.vals[index]
      new_vw = (vw[1] + val, vw[2] + 1)
      @inbounds res.vals[index] = new_vw
    else
      @inbounds res[id] = (val, 1)
    end

  end
  return Dict(k => res[k][1]/res[k][2] for k in keys(res))
end

#Optimized sumby for PooledArrays
function meanby{S}(by::Union{PooledArray, CategoricalArray}, val::AbstractArray{S,1})
  l = length(by.pool)
  res = zeros(S, l)
  wt = zeros(Int64, l)
  refs = Int64.(by.refs)

  for (i, v) in zip(refs, val)
      @inbounds res[i] += v
      @inbounds wt[i] += 1
  end
  return Dict(by.pool[i] => res[i]/wt[i] for i in 1:l)
end

meanby(dt::Union{IndexedTable,AbstractDataFrame},by::Symbol, val::Symbol) = meanby(column(dt,by), column(dt,val))


# function pmeanby{T,S}(by::SharedArray{T,1}, val::SharedArray{S,1})
#   np = nprocs()
#   if np == 1
#     throw(ErrorException("only one proc"))
#   end
#   l = length(by)
#   chunks = sort(collect(Set([1:Int64(round(l/nprocs())):l...,l])))
#
#   ll =length(chunks)
#   res = pmap(2:ll) do i
#     j = Int64(chunks[i-1]):Int64(chunks[i])
#     meanby(by[j], val[j])
#   end
#   return res
# end
#
# function pmeanby{S}(by::Union{PooledArray, CategoricalArray}, val::Vector{S})
#   meanby(by, val)
# end
#
# function pmeanby{T,S}(by::Vector{T}, val::Vector{S})
#   bys = SharedArray(by)
#   vals = SharedArray(val)
#   pmeanby(bys, vals)
# end

# pmeanby(dt::Union{AbstractDataFrame, IndexedTable}, by::Symbol, val::Symbol) = pmeanby(column(dt,by), column(dt,val))
