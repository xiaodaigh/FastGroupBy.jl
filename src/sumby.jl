function sumby_sorted(by_sorted, val)
  res = Dict{T,S}()
  @inbounds tmp_val = val[1]
  @inbounds last_byi = by_sorted[1]
  @inbounds for i in 2:hi
    if val[i] == last_byi
      tmp_val += by_sorted[1]
    else
      res[last_byi] = tmp_val
      tmp_val = val[i]
      last_byi = by_sorted[i]
    end
  end

  @inbounds res[by_sorted[hi]] = tmp_val

  res
end
