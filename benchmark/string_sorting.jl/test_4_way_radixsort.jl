using InternedStrings
const N = 1_000_000; const K = 100
srand(1);
@time sample_space = [string(rand(Char.(97:97+25), rand(1:8))...) for k in 1:N÷K]
@time svec = rand(sample_space, N);

include("src/three_way_radix_quick_sort.jl")

x = svec[1:10]
lo = 1;
hi = length(x);
cmppos = 1;
@time three_way_radix_qsort0!(x)
issorted(x)

lo = 1;
hi = length(svec);
cmppos = 1;
@time three_way_radix_qsort0!(svec);
issorted(svec)

const N = 100_000_000; const K = 100
srand(1);
svec = rand([string(rand(Char.(97:97+25), rand(1:8))...) for k in 1:N÷K], N);

using FastGroupBy
@time radixsort!(svec)
issorted(svec)

using BenchmarkTools, FastGroupBy
const NN = 2^9
srand(1);
svec = rand([string(rand(Char.(97:97+25), rand(1:8))...) for k in 1:NN], NN);
x = @elapsed sort!(svec, alg = InsertionSort)
srand(1);
svec = rand([string(rand(Char.(97:97+25), rand(1:8))...) for k in 1:NN], NN);
y = @elapsed radixsort!(svec)

x < y
