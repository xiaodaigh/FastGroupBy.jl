import SplitApplyCombine.groupreduce

function dict_add_reduce(rr, rr1)
  for k = keys(rr1)
    rr[k] = get(rr, k, 0) + rr1[k]
  end
  return rr
end

function dict_mean_reduce(rr, rr1)
  for k in keys(rr1)
    a = get(rr,k,(0,0))
    b = rr1[k]
    c = (a[1] + b[1], a[2] + b[2])
    rr[k] = c
  end
  rr
end

function pgroupreduce{T}(byfn, map, reduce, hehe, by::SharedArray{T,1}, val::SharedArray{T,1})
  l = length(by)
  ii = sort(collect(Set([1:Int64(round(l/nprocs())):l...,l])))
  res = pmap(2:length(ii)) do i
    iii = ii[i-1]:ii[i]
    groupreduce(byfn, map, reduce, zip(by[iii],val[iii]))
  end
  return Base.reduce(hehe, res)
end
