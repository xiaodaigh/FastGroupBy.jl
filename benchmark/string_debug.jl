
using Revise
using FastGroupBy
import FastGroupBy: load_bits, radixsort!, sorttwo_lsd16!, radixsort8!, sorttwo_lsd!

function cmp_1byte_2byte(M, K, strlen)
    srand(1);
    svec1 = rand([string(rand(Char.(32:126), rand(1:strlen))...) for k in 1:M÷K], M);
    b=@elapsed radixsort8!(svec1);


    srand(1);
    svec1 = rand([string(rand(Char.(32:126), rand(1:strlen))...) for k in 1:M÷K], M);
    c=@elapsed radixsort!(svec1);
    [b,c]
end


@time cmp_1byte_2byte(10_000_000, 100, 8)
@time cmp_1byte_2byte(10_000_000, 100, 16)
@time cmp_1byte_2byte(10_000_000, 100, 24)
@time cmp_1byte_2byte(10_000_000, 100, 32)

@time cmp_1byte_2byte(100_000_000, 100, 8)
@time cmp_1byte_2byte(100_000_000, 100, 16)
@time cmp_1byte_2byte(100_000_000, 100, 24)
@time cmp_1byte_2byte(100_000_000, 100, 32)


# radixsort index is slower
# function cmp_index_1byte_2byte(M, K, strlen)
#     srand(1);
#     svec1 = rand([string(rand(Char.(32:126), rand(1:strlen))...) for k in 1:M÷K], M);
#     a = @elapsed svec2 = radixsort_index(svec1);
    

#     srand(1);
#     svec1 = rand([string(rand(Char.(32:126), rand(1:strlen))...) for k in 1:M÷K], M);
#     b=@elapsed radixsort8!(svec1);


#     srand(1);
#     svec1 = rand([string(rand(Char.(32:126), rand(1:strlen))...) for k in 1:M÷K], M);
#     c=@elapsed radixsort!(svec1);
#     [a,b,c]
# end


# @time cmp_index_1byte_2byte(10_000_000, 100, 8)
# @time cmp_index_1byte_2byte(10_000_000, 100, 16)
# @time cmp_index_1byte_2byte(10_000_000, 100, 24)
# @time cmp_index_1byte_2byte(10_000_000, 100, 32)

# @time cmp_index_1byte_2byte(100_000_000, 100, 8)
# @time cmp_index_1byte_2byte(100_000_000, 100, 16)
# @time cmp_index_1byte_2byte(100_000_000, 100, 24)
# @time cmp_index_1byte_2byte(100_000_000, 100, 32)

