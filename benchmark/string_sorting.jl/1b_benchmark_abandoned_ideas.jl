
function radixsort1!(s::AbstractVector{String})
    sort!(load_bits.(s))
end

function radixsort2!(s::AbstractVector{String})
    sort!(load_bits.(s), alg=RadixSort)
end

using BenchmarkTools

svec1 = copy(svec)
@benchmark radixsort!(svec1)

using SortingAlgorithms
svec1 = copy(svec)
@benchmark radixsort1!(svec1)

# this takes 40 seconds too slow
# svec1 = copy(svec)
# @benchmark sort!(svec1, by = load_bits)
