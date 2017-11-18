# T = Int32
# S = Int32
# j = 1
function sumby_binary_group{T, S<:Number}(by::AbstractVector{T},  val::AbstractVector{S}; init_j = 1, cutsize = 2048)
    # Make sure we're sorting a bits type

    by_sim = similar(by)
    val1 = similar(val)
    l = length(by)
    # if l == 0
    #     return Dict{T,S}()
    # elseif l == 1
    #     return Dict{T,S}(by[1] => val[1])
    # end

    if !isbits(T)
      error("sumby_binary_group on works on bits types (got $T)")
    end

    # Init
    iters = sizeof(T)*8

    # distinct range to groupby over; initially the whole block is one range
    nextranges = Tuple{Int, Int}[]
    push!(nextranges, (1,l))

    mini_results = Dict{T,S}[]

    for j = init_j:iters
        ranges = nextranges::Array{Tuple{Int, Int}}
        nextranges = Tuple{Int,Int}[]
        if length(ranges) == 0
            break
        end
        tic()
        println(length(ranges))
        # println(mean([b - a for (a,b) in ranges]))
        for (lo, hi) in ranges
            bin = [lo, hi]
            # sort

            @inbounds for i = lo:hi
                idx = Int((by[i] >> (j-1)) & 0x01)
                iidx = (1-idx)*bin[1] + idx*bin[2]
                by_sim[iidx] = by[i]
                val1[iidx] = val[i]
                bin[1] += 1 - idx
                bin[2] -= idx
            end


            # are all values the same at this radix?
            if bin[1] == lo | bin[2] == hi
                nextranges = vcat(nextranges, [(lo, hi)])::Array{Tuple{Int, Int}}
            else
                # nextranges = vcat(nextranges, [(lo, bin[1] -1)])
                # nextranges = vcat(nextranges, [(bin[1], hi)])

                #if there are too few elements put into small group
                if bin[1] - lo + 1 <= cutsize
                    # @inbounds bytmp = by_sim[lo:bin[1]-1]
                    # sp = sortperm(bytmp)
                    # @inbounds bytmp_sorted = bytmp[sp]
                    # @inbounds val_sorted = val1[lo:bin[1]-1][sp]
                    # @inbounds by[lo:bin[1]-1], by_sim[lo:bin[1]-1] = bytmp_sorted, bytmp_sorted
                    # @inbounds val[lo:bin[1]-1], val1[lo:bin[1]-1] = val_sorted, val_sorted
                    push!(mini_results, sumby_radixsort(by_sim[lo:bin[1]-1],  val1[lo:bin[1]-1]))
                else
                    nextranges = vcat(nextranges, [(lo, bin[1] -1)])
                end

                if hi - bin[1] <= cutsize
                    # @inbounds bytmp = by_sim[bin[1]:hi]
                    # sp = sortperm(bytmp)
                    # @inbounds bytmp_sorted = bytmp[sp]
                    # @inbounds val_sorted = val1[bin[1]:hi][sp]
                    # @inbounds by[bin[1]:hi], by_sim[bin[1]:hi] = bytmp_sorted, bytmp_sorted
                    # @inbounds val[bin[1]:hi], val1[bin[1]:hi] = val_sorted, val_sorted
                    push!(mini_results, sumby_radixsort(by_sim[bin[1]:hi],  val1[bin[1]:hi]))
                else
                    nextranges = vcat(nextranges, [(bin[1], hi)])
                end
            end
        end

        by, by_sim = by_sim, by
        val, val1 = val1, val
        toc()
    end

    #return mean(by) + mean(by)
    #return (by, val)

    # tic()
    # res =  sumby_contiguous(by, val)::Dict{T,S}
    # toc()

    tic()
    res = mini_results[1]
    szero = zero(S)
    for ms in mini_results[2:end]
        for k in keys(ms)
            res[k] = get(res, k, szero) +  ms[k]
        end
    end
    toc()
    return res
end
