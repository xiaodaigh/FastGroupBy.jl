
cradixsort!(x) = ccall(
    (:radix_sort,"libuntitled3"),
     Void, 
     (Ptr{Ptr{UInt8}},UInt),
    pointer(x), length(x)
)

# test on variable length 8
const M=100_000_000; const K=100
using FastGroupBy
srand(1);
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
@time cradixsort!(svec1) # 50 seconds
issorted(svec1)

srand(1);
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
@time radixsort!(svec1) # 18 seconds
issorted(svec1)


# test on fixed length 10
const M = 100_000_000; const K = 100;
srand(1);
svec = rand(["id"*dec(k,10) for k in 1:M÷K], M);

@time cradixsort(svec) # 2.5 minutes
issorted(svec)

using FastGroupBy
srand(1);
svec = rand(["id"*dec(k,10) for k in 1:M÷K], M);
@time radixsort!(svec) # 18 seconds
issorted(svec)