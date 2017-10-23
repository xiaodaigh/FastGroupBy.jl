using IndexedTables
import DataFrames.DataFrame
import DataFrames.AbstractDataFrame
import IndexedTables.IndexedTable
import Base.ht_keyindex
import IndexedTables.column
import PooledArrays.PooledArray
# using ParallelAccelerator

function meanby{S,T}(id4::AbstractArray{T,1}, v1::AbstractArray{S,1})::Dict{T,Float64}
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
function meanby{S}(by::PooledArray, val::AbstractArray{S,1})
  l = length(by.pool)
  res = zeros(S, l)
  wt = zeros(Int64, l)
  refs = Int64.(by.refs)

  for (i, v) in zip(refs, val)
    res[i] += v
    wt[i] += 1
  end
  return Dict(by.pool[i] => res[i]/wt[i] for i in 1:l)
end

meanby(dt::Union{IndexedTable,AbstractDataFrame},by::Symbol, val::Symbol) = meanby(column(dt,by), column(dt,val))

function column(dt::AbstractDataFrame, col::Symbol)
  i = dt.colindex.lookup[col]
  dt.columns[i]
end

function sumby{T,S}(by::AbstractArray{T,1}, val::AbstractArray{S,1})
  res = Dict{T, S}()
  szero = zero(S)
  for (byi, vali) in zip(by, val)
    index = ht_keyindex(res, byi)
    if index > 0
      @inbounds vw = res.vals[index]
      new_vw = vw + vali
      @inbounds res.vals[index] = new_vw
    else
      @inbounds res[byi] = vali
    end

  end
  return res
end

#Optimized sumby for PooledArrays
function sumby{S}(by::PooledArray, val::AbstractArray{S,1})
  l = length(by.pool)
  res = zeros(S, l)
  refs = Int64.(by.refs)

  for (i, v) in zip(refs, val)
    res[i] += v
  end
  return Dict(by.pool[i] => res[i] for i in 1:l)
end

# @acc function sumby_acc{S}(by::PooledArray, val::AbstractArray{S,1})
#   l = length(by.pool)
#   res = zeros(S, l)
#   refs = Int64.(by.refs)
#
#   for (i, v) in zip(refs, val)
#     res[i] += v
#   end
#   return Dict(by.pool[i] => res[i] for i in 1:l)
# end

sumby(dt::Union{AbstractDataFrame, IndexedTable}, by::Symbol, val::Symbol) = sumby(column(dt,by), column(dt,val))
