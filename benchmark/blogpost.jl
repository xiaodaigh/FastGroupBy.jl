# only need to be run once to install packages
#Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git")
#Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")

using FastGroupBy, PooledArrays
import PooledArrays.PooledArray

#const N = Int(2e9/8)
const N = 250_000_000
const K = UInt(100)

using Base.Threads

function bench_sumby_multi_rs()
    srand(1);
    id6 = rand(Int32(1):Int32(round(N/K)), N);
    v1 =  rand(Int32(1):Int32(5), N);
    @elapsed sumby_multi_rs(id6, v1)
end

function bench_sumby_radixgroup()
    srand(1)
    id6 = rand(Int32(1):Int32(round(N/K)), N)
    v1 =  rand(Int32(1):Int32(5), N)
    # radix sort method
    @elapsed sumby_radixgroup(id6,v1);
end

function bench_sumby_radixsort()
    srand(1)
    id6 = rand(Int32(1):Int32(round(N/K)), N)
    v1 =  rand(Int32(1):Int32(5), N)
    # radix sort method
    @elapsed sumby_radixsort(id6,v1);
end

bench_mrs = [bench_sumby_multi_rs() for i = 1:5]
bench_rg = [bench_sumby_radixgroup() for i = 1:5]
bench_rs = [bench_sumby_radixsort() for i = 1:5]

1 - mean(bench_mrs)/mean(bench_rs) #49.6% faster radixsort
1 - mean(bench_mrs)/mean(bench_rg) #37.2% faster radixgroup

mean(bench_mrs[2:end]) #9.87
mean(bench_rg[2:end]) #15.5
mean(bench_rs[2:end]) #19.2

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
