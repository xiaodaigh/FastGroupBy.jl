
# this is much faster if the sizeof(T) <=1
function sumby_smallT{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S}; j = 1)::Dict{T,S}
  by_sim = similar(by)
  val1 = similar(val)
  hi = length(by)

  if hi == 0
      return Dict{T,S}();
  elseif hi == 1
      return Dict{T,S}(by[1] => val[1])
  end
  o = Forward
  lo = 1

  # Make sure we're sorting a bits type
  #TT = Base.Order.ordtype(o, by)
  # only use this in case of small T & number of uniques in by is smaller
  if sizeof(T) > 1
    error("only use this sort if the sizeof(eltype(by)) <= 1")
  elseif !isbits(T)
    error("Radix sort only sorts bits types (got $T)")
  end

  # Init
  bin1 = zeros(UInt32, 2^RADIX_SIZE) # just one bin for the initial run

  # Histogram for each element, radix
  for i = lo:hi
    v = uint_mapping(o, by[i])
    # perform counting then sort them
    idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
    @inbounds bin1[idx] += 1
  end
  # swaps  = 0
  #len = hi-lo+1
  v = uint_mapping(o, by[hi])
  idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1

  # are all values the same at this radix?
  iters = ceil(Integer, sizeof(T)*8/RADIX_SIZE)

  if bin1[idx] == hi
    #println(by[1])
    #return Dict{T,S}(by[1] => sum(val))
    return sumby(by, val)
  end

  cbin = cumsum(bin1)
  non_empty_cnt = Int.(cbin[vcat(cbin[1] != 0, diff(cbin) .!= 0)])

  ci = cbin[idx]
  by_sim[ci] = by[hi]
  val1[ci] = val[hi]
  cbin[idx] -= 1

  # Finish the loop...
  @inbounds for i in hi-1:-1:lo
      v = uint_mapping(o, by[i])
      idx = @compat(Int((v >> (j-1)*RADIX_SIZE) & RADIX_MASK)) + 1
      ci = cbin[idx]
      by_sim[ci] = by[i]
      val1[ci] = val[i]
      cbin[idx] -= 1
  end

  if iters == j
    #println(countmap(by_sim))
    return sumby_contiguous(by_sim, val1)
  else
    indices = vcat([1:non_empty_cnt[1]],
      [(a+1):b for (a,b) in zip(non_empty_cnt[1:end-1], non_empty_cnt[2:end])]
      )
    return mapreduce(merge, indices) do ii
      sumby_smallT(view(by_sim,ii), view(val1,ii); j = j + 1)
    end
  end
end
