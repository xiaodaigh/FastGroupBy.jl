# only need to be run once to install packages
#Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git")
#Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")

using FastGroupBy, PooledArrays

const N = 100_000_000
# const N = Int(2^31-1) # 368 seconds to run
const K = UInt(100)

using Base.Threads
nthreads()

srand(1)
# generate string ids
function randstrarray1(pool, N)
    K = length(pool)
    PooledArray(PooledArrays.RefArray(rand(1:K, N)), pool)
end
const pool1 = [@sprintf "id%010d" k for k in 1:(N/K)]
const id3 = randstrarray1(pool1, N)
v1 =  rand(Int32(1):Int32(5), N)

# treat it as Pooledarray
@time sumby(id3, v1)

# treat by as strings and use dictionary method; REALLY SLOW
const id3_str = rand(pool1, N)
@time sumby(id3_str, v1)

@time Int.(getindex.(id3_str,1 ))

@time all(isascii.(id3_str))

@time sort(id3_str)
