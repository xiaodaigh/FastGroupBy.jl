function quickgroupby{T, S<:Number}(by::AbstractVector{T}, val::AbstractVector{S})
  j = length(by)
  if j == 1
    return by
  elseif j == 2
    return by
  elseif j  <= 0
    warn("what?")
  end

  pivot = by[1]

  lowergroupi = 1
  i = 2

  while true
    while i <= j
      byi = by[i]
      if byi < pivot
        i += 1
      elseif byi > pivot
        break
      else
         lowergroupi += 1
         by[lowergroupi], by[i] = by[i], by[lowergroupi]
         val[lowergroupi], val[i] = val[i], val[lowergroupi]
         i += 1
      end
    end

    while i <= j
      byj = by[j]
      if pivot < byj
        j -= 1
      elseif pivot > byj
        break
      else
        lowergroupi += 1
        by[lowergroupi], by[j], by[i] = by[j], by[i], by[lowergroupi-1]
        val[lowergroupi], val[j], val[i] = val[j], val[i], val[lowergroupi-1]
        j -= 1
        i += 1
      end
    end

    if i > j
      # print(by[i])
      # print(by[j])
      break
    end
    by[i], by[j] = by[j], by[i]
    val[i], val[j] = val[j], val[i]
    i += 1
    j -= 1
  end

  # println(by)
  # println(lowergroupi+1)
  # println(i)
  # println(j)

  if lowergroupi == length(by)
    return by
  elseif i > length(by) || ((lowergroupi + 1) > (i-1))
    lby = quickgroupby(by[(lowergroupi+1):end],val[(lowergroupi+1):end])
    return vcat(by[1:lowergroupi], lby)
  else
    lby = quickgroupby(by[(lowergroupi+1):(i-1)],val[(lowergroupi+1):(i-1)])
    rby = quickgroupby(by[i:end],val[i:end])
    return vcat(by[1:lowergroupi], lby, rby)
  end
end
#
# x = rand(1:3, 10)
# by = copy(x)
# val = copy(x)
# quickgroupby(by,val)
# const N = 10_000_000
# const K = 100
# addprocs()
# id6 = rand(1:(N/K), N)
# sid6 = SharedArray(id6)
# v1 = similar(id6)
# @time quickgroupby(id6, v1)
#
# using FastGroupBy
# @time sumby(id6,v1)
