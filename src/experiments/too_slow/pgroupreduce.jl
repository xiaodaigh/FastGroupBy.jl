function dict_add_reduce(local_res)
  res = reduce(local_res) do  rr, rr1
    for k = keys(rr1)
      rr[k] = get(rr, k, 0) + rr1[k]
    end
    return rr
  end
  return res
end

function dict_mean_reduce(local_res)
  res = reduce(local_res) do rr, rr1
    for k in keys(rr1)
      a = get(rr,k,(0,0))
      b = rr1[k]
      c = (a[1] + b[1], a[2] + b[2])
      rr[k] = c
    end
    rr
  end
  res
end

function pgroupreduce{T}(byfn, map, local_reduce, master_reduce, by::SharedArray{T,1}, val::SharedArray{T,1})
  if nprocs()==1
    throw(ErrorException("Only 1 worker; use groupreduce instead"))
  end
  l = length(by)
  ii = sort(collect(Set([1:Int64(round(l/nprocs())):l...,l])))
  res = pmap(2:length(ii)) do i
    iii = ii[i-1]:ii[i]
    groupreduce(byfn, map, local_reduce, zip(by[iii],val[iii]))
  end
  return master_reduce(res)
end
