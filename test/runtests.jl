# using Revise
using FastGroupBy, StatsBase, DataFrames, Random
# using SortingAlgorithms
import DataFrames.DataFrame
using Test
using CategoricalArrays, PooledArrays

# include("fgroupreduce_fby.jl")

N=1_000_000; K=100;

# fastby for CategoricalArrays and PooledArrays

if false
    pools = unique([randstring(rand(1:32)) for i = 1:N÷K]);
    byvec = CategoricalArray{String, 1}(rand(UInt32(1):UInt32(length(pools)), N), CategoricalPool(pools, false));
    valvec = rand(N);
    @time cmres = countmap(byvec, weights(valvec)); #76
    @time fnrs = fastby(sum, byvec, valvec); # 24
    @test length(cmres) == length(fnrs)
    @test all([cmres[k] ≈ fnrs[k] for k in keys(cmres)])

    byvec = PooledArray(PooledArrays.RefArray(rand(UInt32(1):UInt32(length(pools)), N)), pools);
    @time cmres = countmap(byvec, weights(valvec)); #38
    @time fnrs = fastby(sum, byvec, valvec); # 21
    @test length(cmres) == length(fnrs)
    @test all([cmres[k] ≈ fnrs[k] for k in keys(cmres)])

    # Basic sumby and fastby
    a = [1, 1, 2, 3, 3];
    aa = sumby!(a,copy(a));
    aaa = fastby!(sum,a,copy(a))
    b = Dict(1 => 2, 2 => 2, 3 => 6)
    @test aa == b
    @test aaa == b



    # fastby sum

    byvec  = [88, 888, 8, 88, 888, 88]
    valvec = [1 , 2  , 3, 4 , 5  , 6]
    grpsum = fastby!(sum, byvec, valvec)
    expected_result = Dict(88 => 11, 8 => 3, 888 => 7)
    @test grpsum == expected_result

    # fastby string
    byvec  = ["grpA", "grpC", "grpB", "grpA", "grpC", "grpA"]
    valvec = [1     , 2     , 3     , 4     , 5     , 6     ]
    grpsum = fastby!(sum, byvec, valvec)
    expected_result = Dict("grpA" => 11, "grpB" => 3, "grpC" => 7)
    @test grpsum == expected_result

    # fastby Bool
    byvec = rand(Bool, 1_000_000)
    valvec = rand(1_000_000)
    x = fastby!(sum, byvec, valvec)
    y = countmap(byvec, weights(valvec))
    @test length(x)  == length(y) && [x[k] ≈ y[k] for k = keys(x)] |> all


    # sumby vs DataFrames.aggregate
    Random.seed!(1);
    id = rand(1:Int(round(N/K)), N);
    val = rand(round.(rand(K)*100,4), N);
    df = DataFrame(id = id, val = val);
    @time x = DataFrames.aggregate(df, :id, sum); # 3.3 seconds
    @time y = sumby!(df, :id, :val); # 0.4
    xdict = Dict(zip(x[:id],x[:val_sum]))
    length(xdict) == length(y) && [xdict[k] ≈ y[k] for k in keys(xdict)] |> all
end
