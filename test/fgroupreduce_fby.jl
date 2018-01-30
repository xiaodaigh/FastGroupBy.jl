#######################################################################
# setting up
#######################################################################
using Revise
using FastGroupBy, BenchmarkTools, SortingLab, CategoricalArrays, Base.Test
tic()
# import Base: getindex, similar, setindex!, size
N = 1_000_000; K = 100
srand(1);
# val = rand(round.(rand(K)*100,4), N);
val = rand(1:5, N);
pool = "id".*dec.(1:100,3);
fn = sum;

#######################################################################
# convert to CategoricalVector
#######################################################################
y = CategoricalArray{String, 1}(rand(UInt32(1):UInt32(length(pool)), N), CategoricalPool(pool, true));
y = compress(y);
# @benchmark sort($y)

z = CategoricalArray{String, 1}(rand(UInt32(1):UInt32(length(pool)), N), CategoricalPool(pool, true));
z = compress(z);
byveccv = (y, z);
toc() # 2mins for 2b length vectors

tic()
@benchmark fgroupreduce($+, $byveccv, $val) # 7.5 seconds for 2billion
res1 = fgroupreduce(+, byveccv, val) 
res1max = fgroupreduce(max, byveccv, val) 
toc()

tic()
@benchmark fby($sum, $byveccv, $val)
res = fby(sum, byveccv, val)
# @code_warntype fby(sum, byveccv, val)
toc()

@test all(res[1] .== res1[1])
@test all(res[2] .== res1[2])
@test all(res[3] .== res1[3])