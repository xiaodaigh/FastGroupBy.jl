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