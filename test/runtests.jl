using Revise
using FastGroupBy, StatsBase, DataFrames
# using SortingAlgorithms
import DataFrames.DataFrame
using Base.Test
using CategoricalArrays, PooledArrays

const M=10_000_000; const K=100; 

# fastby for CategoricalArrays and PooledArrays
tic()
pools = unique([randstring(rand(1:32)) for i = 1:M÷K]);
byvec = CategoricalArray{String, 1}(rand(UInt32(1):UInt32(length(pools)), M), CategoricalPool(pools, false));
valvec = rand(M);
@time cmres = countmap(byvec, weights(valvec)); #76
@time fnrs = fastby(sum, byvec, valvec); # 24
@test length(cmres) == length(fnrs)
@test all([cmres[k] ≈ fnrs[k] for k in keys(cmres)])

byvec = PooledArray(PooledArrays.RefArray(rand(UInt32(1):UInt32(length(pools)), M)), pools);
@time cmres = countmap(byvec, weights(valvec)); #38
@time fnrs = fastby(sum, byvec, valvec); # 21
@test length(cmres) == length(fnrs)
@test all([cmres[k] ≈ fnrs[k] for k in keys(cmres)])


pools = unique([randstring(rand(1:32)) for i = 1:M÷K]);
byvec = CategoricalArray{String, 1}(rand(UInt32(1):UInt32(length(pools)), M), CategoricalPool(pools, false));
valvec = rand(M);
@time cmres = countmap(byvec, weights(valvec)); #76
@time fnrs = fastby!(sum, byvec, valvec); # 24
@test length(cmres) == length(fnrs)
@test all([cmres[k] ≈ fnrs[k] for k in keys(cmres)])

byvec = PooledArray(PooledArrays.RefArray(rand(UInt32(1):UInt32(length(pools)), M)), pools);
valvec = rand(M);
@time cmres = countmap(byvec, weights(valvec)); #38
@time fnrs = fastby!(sum, byvec, valvec); # 21
@test length(cmres) == length(fnrs)
@test all([cmres[k] ≈ fnrs[k] for k in keys(cmres)])
toc()

# String sort
tic()
# const M=1000; const K=100; 
svec1 = rand([Base.randstring(rand(1:32)) for k in 1:M÷K], M);
@time res1 = sort(svec1, alg = StringRadixSort)
@test issorted(res1)

@time res1 = sort(svec1, alg = StringRadixSort, rev = true)
@test issorted(res1, rev = true)

@time res1 = sort(svec1, alg = StringRadixSort, rev=true)
@test issorted(res1, rev = true)

@time sort!(svec1);
@test issorted(svec1)

svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
@time radixsort_lsd!(svec1);
@test issorted(svec1)

svec1 = rand([string(rand(Char.(32:126), rand(1:16))...) for k in 1:M÷K], M);
@time radixsort_lsd!(svec1);
@test issorted(svec1)

svec1 = rand([string(rand(Char.(32:126), rand(1:24))...) for k in 1:M÷K], M);
@time radixsort_lsd!(svec1);
@test issorted(svec1)

svec1 = rand([string(rand(Char.(32:126), rand(1:32))...) for k in 1:M÷K], M);
@time radixsort_lsd!(svec1);
@test issorted(svec1)
toc()

# Basic sumby and fastby
tic()
a = [1, 1, 2, 3, 3];
aa = sumby!(a,copy(a));
aaa = fastby!(sum,a,copy(a))
b = Dict(1 => 2, 2 => 2, 3 => 6)
@test aa == b
@test aaa == b
toc()


# fastby sum
tic()
byvec  = [88, 888, 8, 88, 888, 88]
valvec = [1 , 2  , 3, 4 , 5  , 6]
grpsum = fastby!(sum, byvec, valvec)
expected_result = Dict(88 => 11, 8 => 3, 888 => 7)
@test grpsum == expected_result

# fastby string
byvec  = ["grpA", "grpC", "grpB", "grpA", "grpC", "grpA"]
valvec = [1     , 2     , 3     , 4     , 5     , 6     ]
grpsum = fastby!(sum, byvec, valvec)
@which fastby!(sum, byvec, valvec)
expected_result = Dict("grpA" => 11, "grpB" => 3, "grpC" => 7)
@test grpsum == expected_result

# fastby Bool
byvec = rand(Bool, 1_000_000)
valvec = rand(1_000_000)
x = fastby!(sum, byvec, valvec)
y = countmap(byvec, weights(valvec))
@test length(x)  == length(y) && [x[k] ≈ y[k] for k = keys(x)] |> all
toc()

# sumby vs DataFrames.aggregate
tic()
srand(1);
id = rand(1:Int(round(M/K)), M);
val = rand(round.(rand(K)*100,4), M);
df = DataFrame(id = id, val = val);
@time x = DataFrames.aggregate(df, :id, sum); # 3.3 seconds
@time y = sumby!(df, :id, :val); # 0.4
xdict = Dict(zip(x[:id],x[:val_sum]))
length(xdict) == length(y) && [xdict[k] ≈ y[k] for k in keys(xdict)] |> all
toc()

