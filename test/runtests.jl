using FastGroupBy, StatsBase, DataFrames
import DataFrames.DataFrame
using Base.Test

tic()
a = [1, 1, 2, 3, 3];
aa = sumby!(a,copy(a));
aaa = fastby!(sum,a,copy(a))
b = Dict(1 => 2, 2 => 2, 3 => 6)
@test aa == b
@test aaa == b
toc()

tic()
const M=1000; const K=100; 
# srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
radixsort!(svec1)
@test issorted(svec1)
toc()

tic()
byvec  = [88, 888, 8, 88, 888, 88]
valvec = [1 , 2  , 3, 4 , 5  , 6]
grpsum = fastby!(sum, byvec, valvec)
expected_result = Dict(88 => 11, 8 => 3, 888 => 7)
@test grpsum == expected_result

byvec  = ["grpA", "grpC", "grpB", "grpA", "grpC", "grpA"]
valvec = [1     , 2     , 3     , 4     , 5     , 6     ]
grpsum = fastby!(sum, byvec, valvec)
expected_result = Dict("grpA" => 11, "grpB" => 3, "grpC" => 7)
@test grpsum == expected_result

byvec = rand(Bool, 1_000_000)
valvec = rand(1_000_000)
x = fastby!(sum, byvec, valvec)
y = countmap(byvec, weights(valvec))
@test length(x)  == length(y) && [x[k] ≈ y[k] for k = keys(x)] |> all
toc()

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

