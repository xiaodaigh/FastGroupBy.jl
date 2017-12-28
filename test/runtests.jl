using FastGroupBy
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
const M=1000; const K=100
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
toc()