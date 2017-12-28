import FastGroupBy: grouptwo!
using BenchmarkTools

const N = 200_000_000
const K = 100

srand(1);
x = rand(1:N÷K, N);
y = rand(N);

@time grouptwo!(x,y); # 2.95