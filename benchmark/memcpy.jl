srand(1)
M = 10_000_000; K = 100
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
# memcmp("abc","def",3)
memcmp(a::String, b::String, sz) = ccall(:memcmp, Int32, (Ptr{UInt8}, Ptr{UInt8}, Int32), pointer(a), pointer(b), sz)

@time sort!(svec1, lt=(x,y)->memcmp(x,y,8)<0, alg=QuickSort); # 2.7 seconds
issorted(svec1)
