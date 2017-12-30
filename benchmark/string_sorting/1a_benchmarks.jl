using FastGroupBy,RCall

const M=100_000_000; const K=100;
srand(1);
svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M);
@time radixsort!(svec1); #18, 18.6, 17.24
issorted(svec1);

R"""
memory.limit(2e9)
N=$M; K=$K
set.seed(1)
library(data.table)
id3 = sample(sprintf("i%07d",1:(N/K)), N, TRUE)
pt = proc.time()
system.time(sort(id3, method="radix"))
data.table::timetaken(pt) # 18.9, 20.6 22.1
"""

# Roughly on par with R for length 8 id strings

# using longer string to compare speed
srand(1);
svec1 = rand(["id"*dec(k,10) for k in 1:M÷K], M);
@time radixsort!(svec1); # 26.89
issorted(svec1);

R"""
memory.limit(2e9)
N=$M; K=$K
set.seed(1)
library(data.table)
id3 = sample(sprintf("i%010d",1:(N/K)), N, TRUE)
pt = proc.time()
system.time(sort(id3, method="radix"))
data.table::timetaken(pt) # 23.1
"""

# Roughly on par with R for length 10 id strings; but is about 3 seconds slower

# sorting strings of variable length upto length 8
const M=10_000_000; const K=100;
srand(1);
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
@time sort!(svec1); # 50 seconds
issorted(svec1)

using RCall
R"""
memory.limit(2e9)
N=$M; K=$K
set.seed(1)
library(data.table)
bs = sapply(1:(N/K), function(i) rawToChar(sample(as.raw(32:126), sample(8), replace=T)))
id3 = sample(bs, N, replace = T)
pt = proc.time()
system.time(sort(id3, method="radix"))
data.table::timetaken(pt) #24.2
"""

# using longer string to compare speed
srand(1);
svec1 = rand([string(rand(Char.(32:126), rand(1:16))...) for k in 1:M÷K], M);
# using FastGroupBy.radixsort! to sort strings of length 16
@time radixsort!(svec1); # 41 seconds on 100m
issorted(svec1)

R"""
memory.limit(2e9)
N=$M; K=$K
set.seed(1)
library(data.table)
bs = sapply(1:(N/K), function(i) rawToChar(sample(as.raw(32:126), sample(8), replace=T)))
id3 = sample(bs, N, replace = T)
pt = proc.time()
system.time(sort(id3, method="radix"))
data.table::timetaken(pt) #24.2
"""

# Slower than R for length of 16; 1.7x times slower