
const x = "id0000248523"
using BenchmarkTools
@benchmark hash.(svec) #17 seconds
@benchmark load_bits.(svec) #3.2 seconds

@time const a = load_bits.(svec)
using SortingAlgorithms
@time sort!(a, alg=RadixSort)


srand(1)
svec = rand(["id"*dec(k,10) for k in 1:M÷K], M)
@sort svec
@time radixsort!()



# the most economical is too load the machinesize
@benchmark load_bits(x)!
@benchmark load_bits(UInt128, x)
@benchmark load_bits(UInt32, x)

@benchmark load_bits(x, 8)
@benchmark load_bits(UInt128, x, 8)
@benchmark load_bits(UInt128, x, 8)

@benchmark hash(x)
@benchmark Vector{UInt8}(x)

load_bits(x)
load_bits(UInt128, x)
load_bits(UInt32, x)
