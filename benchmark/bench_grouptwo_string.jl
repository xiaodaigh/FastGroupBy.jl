using Revise
using FastGroupBy, BenchmarkTools
import FastGroupBy: fcollect, load_bits, roughhash
const N = Int(1e7);const K =100;
srand(1);
byvec = rand(["id"*dec(k,10) for k = 1:N÷K],N);
valvec = rand(N);
# @time FastGroupBy.radixsort_ntoh!(byvec)
@btime radixsort!($byvec)
@btime radixsort8!($byvec)

@time x = ntoh.(unsafe_load.(Ptr{UInt}.(pointer.(byvec))))

def(byvec) =  ntoh.(unsafe_load.(Ptr{UInt}.(pointer.(byvec))))
@time def(byvec)
@time byvec2 = grouptwo!(byvec, valvec); #42




@time FastGroupBy._contiguousby(sum, byvec2[1], byvec2[2]);

#rl is random length
byvec_rl = rand(["id"*dec(k,rand(1:10)) for k = 1:N÷K],N);


@time hh = hash.(byvec);
@time grouptwo!(hh, byvec)

@time load_bits.(byvec);
@time roughhash.(byvec);

@time x = unsafe_load(Ptr{UInt}(pointer("abc")))
@time ntoh(x)

@time hash.(byvec_rl);
@time load_bits.(byvec_rl);
@time load_bits.(byvec_rl, 8);
@time load_bits2.(byvec_rl);
@time roughhash.(byvec_rl);

# roughhash(byvec[1])
# load_bits(byvec[1])

@time unsafe_load.(Ptr{UInt}.(pointer.(byvec)))
@time load_bits.(byvec)

@time byvec2 = grouptwo!(byvec, valvec); #42
@time FastGroupBy._contiguousby(sum, byvec2[1], byvec2[2]);


@time radixsort!(byvec)

# using StatsBase
# srand(1);
# byvec = rand(["id"*dec(k,10) for k = 1:N÷K],N);
# valvec = rand(N);
# @time cm = countmap(byvec, weights(valvec)); # 41.7

# @code_warntype  grouptwo!(byvec, valvec);
\