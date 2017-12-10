svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
@time radixsort!(svec1)
issorted(svec1)


x = load_bits.(["i1000000","i09999999"])
y = copy(x)
sorttwo2!(x,y)

x= "abcdefgh"
y ="bbcdefgh"
skipbytes=0
T=UInt
unsafe_load(Ptr{UInt64}(pointer(x)))
unsafe_load(Ptr{UInt64}(pointer(y)))
