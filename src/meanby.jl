using IndexedTables
import DataFrames.DataFrame
function meanby{S,T}(id4::Vector{T}, v1::Vector{S})::Dict{T,Float64}
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

meanby(dt::IndexedTables.IndexedTable,by::Symbol, val::Symbol) = meanby(column(dt,by), column(dt,val))
meanby(dt::DataFrame,by::Symbol, val::Symbol) = meanby(column(dt,by), column(dt,val))

import IndexedTables.column
function column(dt::DataFrame, col::Symbol)
  i = dt.colindex.lookup[col]
  dt.columns[i]
end
