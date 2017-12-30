const M=100_000_000; const K=100;
srand(1);
svec1 = rand([string(rand(Char.(32:126), 16)...) for k in 1:M÷K], M);

using FastGroupBy
@time x= FastGroupBy.load_bits.(UInt128, svec1);
@time grouptwo!(x, svec1)
@time x = ntoh.(x);
@time sorttwo!(x, svec1);
issorted(svec1)