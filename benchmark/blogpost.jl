# only need to be run once to install packages
#Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git")
#Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")

using FastGroupBy, PooledArrays
import PooledArrays.PooledArray

const N = Int(2e9/8)
const K = UInt(100)

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

bench_rg = [bench_sumby_radixgroup() for i = 1:5]
bench_rs = [bench_sumby_radixsort() for i = 1:5]

1 - mean(bench_rg)/mean(bench_rs) #18% faster
1 - mean(bench_rg[2:end])/mean(bench_rs[2:end]) #21% faster

mean(bench_rg[2:end]) #14.9
mean(bench_rs[2:end]) #18.9

# generate string ids
function randstrarray1(pool, N)
    K = length(pool)
    PooledArray(PooledArrays.RefArray(rand(1:K, N)), pool)
end

const pool1 = [@sprintf "id%010d" k for k in 1:(N/K)]
const id3 = randstrarray1(pool1, N)

# treat it as Pooledarray
@time sumby(id3, v1)

# treat by as strings and use dictionary method
const id3_str = rand(pool1, N)
@time sumby_dict(id3_str, v1)

# parallelized sum
@time addprocs() # create Julia workers
@time using FastGroupBy
@everywhere using FastGroupBy
@everywhere using SplitApplyCombine
@time psumby(id6,v1) # 35 seconds
