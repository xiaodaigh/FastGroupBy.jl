function psumby{T,S<:Number}(by::SharedArray{T,1}, val::SharedArray{S,1})
  np = nprocs()
  if np == 1
    throw(ErrorException("only one proc"))
  end
  l = length(by)
  res = [@spawnat k sumby_res = sumby(by[localindexes(by)], val[localindexes(val)]) for k = 2:np]

  # ress = pmap(res) do res1
  #   next_res = fetch(res1)
  #   szero = zero(S)
  #   for k = keys(next_res)
  #     sumby_res[k] = get(sumby_res, k, szero) + next_res[k]
  #   end
  #   sumby_res
  # end

  # algorithms to collate all dicts

  fnl_res = fetch(res[1])
  szero = zero(S)
  for i = 2:length(res)
    next_res = fetch(res[i])
    for k = keys(next_res)
      fnl_res[k] = get(fnl_res, k, szero) + next_res[k]
    end
  end
  fnl_res
end

function psumby{S<:Number}(by::Union{PooledArray, CategoricalArray}, val::Vector{S})
  return sumby(by, val)
end

function psumby{T,S<:Number}(by::Vector{T}, val::Vector{S})
  bys = SharedArray(by)
  vals = SharedArray(val)
  return psumby(bys, vals)
end

psumby(dt::Union{AbstractDataFrame, NDSparse}, by::Symbol, val::Symbol) = psumby(column(dt,by), column(dt,val))
