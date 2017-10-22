using FastGroupBy
using Base.Test
import Base.ht_keyindex

# write your own tests here
@test 1 == 1

using DataBench, IndexedTables, PooledArrays
@time DT = createIndexedTable(Int64(2e9/8), 100);
@time sumby(column(DT, :id1), column(DT, :v1))
@time sumby(column(DT, :id1), column(DT, :v1))

@time sumby(DT,  :id1,  :v1)
@time sumby(DT,  :id1,  :v1)

@time sumby(DT,  :id6,  :v1)

@which sumby(DT,  :id6,  :v1)


using DataBench, FastGroupBy, IndexedTables
import IndexedTables.IndexedTable
dt = createIndexedTable(1_000_000, 100);

import Base.@pure
@pure eltypes(T) = Tuple{map(eltype, T.parameters)...}

j = 0
bycolumns = columns(dt, (:id1,:id4));
for (i,c) in enumerate(bycolumns)
  j = i
end
print(j)
length(dt)

import FastGroupBy.meanby
import Base.ht_keyindex
function meanby(dt::IndexedTable, by::Tuple{Symbol, Symbol}, val::Symbol)
  l = length(dt)
  bycolumns = columns(dt, by);
  wt = zeros(Int64, l)

  valcol = column(dt, val)
  tt = eltypes(typeof(bycolumns))
  d = Dict{tt, Float64}()
  wt = Dict{tt, Int64}()

  for (i, el) in enumerate(zip(bycolumns...))
    index = ht_keyindex(d, el)
    if index > 0
      @inbounds d.vals[index] += valcol[i]
      @inbounds wt.vals[index] += 1
    else
      @inbounds d[el] = valcol[i]
      @inbounds wt[el] = 1
    end
  end
  return Dict(k => d[k]/wt[k] for k in keys(d))
end

@time res = meanby(dt, (:id1,:id4), :v1)

@time dt = createIndexedTable(Int64(2e9/8), 100);
@time res = meanby(dt, (:id1,:id4), :v1);

function randstrarray(pool, N, K)
    PooledArray(PooledArrays.RefArray(rand(UInt8(1):UInt8(K), N)), pool)
end
