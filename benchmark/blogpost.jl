# only need to be run once to install packages
#Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git")
#Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")

using FastGroupBy, PooledArrays
import PooledArrays.PooledArray

const N = 100_000_000
# const N = Int(2^31-1) # 368 seconds to run
const K = UInt(100)

using Base.Threads
nthreads()

# srand(1);
# by = rand(Int32(1):Int32(round(N/K)), N);
# val =  rand(Int32(1):Int32(5), N);
# @code_warntype sumby_binary_group(by, val)
# @time sumby_binary_group(by, val)
#
# @time bench_sumby_multi_rs()
# @time bench_sumby_radixsort()

srand(1);
id6 = rand(Int64(1):Int64(round(N/K)), N);
v1 =  rand(Int64(1):Int64(5), N);
gc()
@elapsed sumby_multi_rs(id6, v1)

srand(1);
id4 = rand(Int64(1):Int64(K), N);
gc()
@elapsed sumby_multi_rs(id4, v1)


srand(1);
id6 = rand(Int32(1):Int32(round(N/K)), N);
v1 =  rand(Int32(1):Int32(5), N);
gc()
@elapsed sumby_multi_rs(id6, v1)

srand(1);
id4 = rand(Int32(1):Int32(K), N);
gc()
@elapsed sumby_multi_rs(id4, v1)

function bench_sumby_multi_rs()
    srand(1);
    # id6 = rand(Int32(1):Int32(round(N/K)), N);
    # v1 =  rand(Int32(1):Int32(5), N);
    gc()
    @elapsed sumby_multi_rs(id6, v1)
end

function bench_sumby_radixgroup()
    srand(1)
    id6 = rand(Int32(1):Int32(round(N/K)), N)
    # v1 =  rand(Int32(1):Int32(5), N)
    # radix sort method
    gc()
    @elapsed sumby_radixgroup(id6,v1);
end

function bench_sumby_radixsort()
    srand(1)
    id6 = rand(Int32(1):Int32(round(N/K)), N)
    # v1 =  rand(Int32(1):Int32(5), N)
    # radix sort method
    gc()
    @elapsed sumby_radixsort(id6,v1);
end

function bench_sumby_radixsort_extra()
    srand(1)
    id6 = rand(Int32(1):Int32(round(N/K)), N)
    # v1 =  rand(Int32(1):Int32(5), N)
    # radix sort method
    gc()
    @elapsed sumby_radixsort_extra(id6,v1);
end

@time bench_mrs = [bench_sumby_multi_rs() for i = 1:3]
# @time bench_rg = [bench_sumby_radixgroup() for i = 1:3]
@time bench_rs = [bench_sumby_radixsort() for i = 1:5]
@time bench_rse = [bench_sumby_radixsort_extra() for i = 1:5]

using HypothesisTests
p1 = pvalue(EqualVarianceTTest(bench_rs, bench_rse))
p2 = pvalue(UnequalVarianceTTest(bench_rs, bench_rse))
while (p1 >= 0.05) | (p2 >= 0.05)
    @time bench_rs = vcat(bench_rs, [bench_sumby_radixsort()])
    @time bench_rse =  vcat(bench_rse, [bench_sumby_radixsort_extra()])
    p1 = pvalue(EqualVarianceTTest(bench_rs, bench_rse))
    p2 = pvalue(UnequalVarianceTTest(bench_rs, bench_rse))
end
mean(bench_rs[2:end]) #19.2
mean(bench_rse[2:end])
p1 = pvalue(EqualVarianceTTest(bench_rs, bench_rse))
p2 = pvalue(UnequalVarianceTTest(bench_rs, bench_rse))

1 - mean(bench_rs)/mean(bench_rse) # the new version is faster
1 - mean(bench_mrs)/mean(bench_rs) #49.6% faster radixsort
# 1 - mean(bench_mrs)/mean(bench_rg) #37.2% faster radixgroup

mean(bench_mrs[2:end]) #9.87
# mean(bench_rg[2:end]) #15.5
mean(bench_rs[2:end]) #19.2
mean(bench_rse[2:end])

# generate string ids
function randstrarray1(pool, N)
    K = length(pool)
    PooledArray(PooledArrays.RefArray(rand(1:K, N)), pool)
end

srand(1)
const pool1 = [@sprintf "id%010d" k for k in 1:(N/K)]
const id3 = randstrarray1(pool1, N)
v1 =  rand(Int32(1):Int32(5), N)

# treat it as Pooledarray
@time sumby(id3, v1)

# treat by as strings and use dictionary method; REALLY SLOW
const id3_str = rand(pool1, N)
@time sumby_dict(id3_str, v1)

# parallelized sum
# @time addprocs() # create Julia workers
# @time using FastGroupBy
# @everywhere using FastGroupBy
# @everywhere using SplitApplyCombine
# @time psumby(id6,v1) # 35 seconds
