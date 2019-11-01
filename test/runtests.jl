using Revise
using FastGroupBy, StatsBase, DataFrames, Random
# using SortingAlgorithms
import DataFrames: DataFrame
using Test
using CategoricalArrays, PooledArrays

# include("fgroupreduce_fby.jl")

N=1_000_000; K=100;

# fastby for CategoricalArrays and PooledArrays

# TODO
pools = unique([randstring(rand(1:32)) for i = 1:N÷K]);
byvec = CategoricalArray{String, 1}(rand(UInt32(1):UInt32(length(pools)), N), CategoricalPool(pools, false));
valvec = rand(N);
@time cmres = countmap(byvec, weights(valvec)); #76
@time fnrs = fastby(sum, byvec, valvec); # 24

fnrsdict = Dict(zip(fnrs[1], fnrs[2]))

@test length(cmres) == length(fnrs[1])
@test all([cmres[k] ≈ fnrsdict[k] for k in keys(cmres)])

byvec = PooledArray(String.(byvec));
@time cmres = countmap(byvec, weights(valvec)); #38
@time fnrs = fastby(sum, byvec, valvec); # 21

fnrsdict = Dict(zip(fnrs[1], fnrs[2]))
@test length(cmres) == length(fnrsdict)
@test all([cmres[k] ≈ fnrsdict[k] for k in keys(cmres)])

# test sum
b = rand(1:1_000_000, 100_000_000)
@time res = fastby(sum, b, [1 for i in 1:100_000_000])
@time rescm = countmap(b)

resdict = Dict(zip(res...))

@test length(rescm) == length(resdict)
@test all([rescm[k] == resdict[k] for k in keys(resdict)])

# test mean
@time res = fastby(mean, b, [1 for i in 1:100_000_000])

resdict = Dict(zip(res...))

@test 1_000_000 == length(resdict)
@test all([1.0 == resdict[k] for k in keys(resdict)])


# Basic sumby and fastby!
a = [1, 1, 2, 3, 3];
aaa = fastby!(sum, a, copy(a))
b = Dict(1 => 2, 2 => 2, 3 => 6)
aaab = Dict(a=>b for (a,b) in zip(aaa...))
@test aaab == b

# Basic sumby and fastby
a = [1, 1, 2, 3, 3];
aaa = fastby(sum, a, copy(a))
b = Dict(1 => 2, 2 => 2, 3 => 6)
aaab = Dict(a=>b for (a,b) in zip(aaa...))
@test aaab == b

# fastby! sum
byvec  = [88, 888, 8, 88, 888, 88]
valvec = [1 , 2  , 3, 4 , 5  , 6]
grpsum = fastby!(sum, byvec, valvec)
expected_result = Dict(88 => 11, 8 => 3, 888 => 7)
@test Dict(a=>b for (a,b) in zip(grpsum...)) == expected_result

# fastby sum
byvec  = [88, 888, 8, 88, 888, 88]
valvec = [1 , 2  , 3, 4 , 5  , 6]
grpsum = fastby(sum, byvec, valvec)
expected_result = Dict(88 => 11, 8 => 3, 888 => 7)
@test Dict(a=>b for (a,b) in zip(grpsum...)) == expected_result

# fastby! string
byvec  = ["grpA", "grpC", "grpB", "grpA", "grpC", "grpA"]
valvec = [1     , 2     , 3     , 4     , 5     , 6     ]
grpsum = fastby!(sum, byvec, valvec)
expected_result = Dict("grpA" => 11, "grpB" => 3, "grpC" => 7)
@test Dict(a=>b for (a,b) in zip(grpsum...)) == expected_result

# fastby string
byvec  = ["grpA", "grpC", "grpB", "grpA", "grpC", "grpA"]
valvec = [1     , 2     , 3     , 4     , 5     , 6     ]
grpsum = fastby(sum, byvec, valvec)
expected_result = Dict("grpA" => 11, "grpB" => 3, "grpC" => 7)
@test Dict(a=>b for (a,b) in zip(grpsum...)) == expected_result

# fastby! Bool
byvec = rand(Bool, 1_000_000)
valvec = rand(1_000_000)
x = fastby!(sum, byvec, valvec)
y = countmap(byvec, weights(valvec))
@test length(Dict(zip(x...)))  == length(y) && [Dict(zip(x...))[k] ≈ y[k] for k = keys(y)] |> all

# fastby Bool
byvec = rand(Bool, 1_000_000)
valvec = rand(1_000_000)
x = fastby(sum, byvec, valvec)
y = countmap(byvec, weights(valvec))
@test length(Dict(zip(x...)))  == length(y) && [Dict(zip(x...))[k] ≈ y[k] for k = keys(y)] |> all


# sumby vs DataFrames.aggregate
Random.seed!(1);
id = rand(1:Int(round(N/K)), N);
val = rand(round.(rand(K)*100, digits = 4), N);
df = DataFrame(id = id, val = val);
@time x = DataFrames.aggregate(df, :id, mean); # 3.3 seconds
#@time x = by(df, :id, val = :val => sum); # 3.3 seconds
xdict = Dict(zip(x[!, :id], x[!, :val_mean]))
res = fastby(mean, df, :id, :val)
y = Dict(a=>b for (a,b) in zip(res[!,:id], res[!,:V1]))
length(xdict) == length(y) && [xdict[k] ≈ y[k] for k in keys(xdict)] |> all
#end
