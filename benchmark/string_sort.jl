using Revise
using FastGroupBy
const M=1000; const K=100
srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
@time radixsort!(svec1)
issorted(svec1)

include("src/sorttwo_lsd16.jl")
const M=10_000_000; const K=100
srand(1)
# @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
# @time fast(svec1)
@time radixsort!(svec1) # 3 seconds on 10m; 41 seconds on 100m;
# @code_warntype radixsort!(svec1)
issorted(svec1)

const M=10_000_000; const K=100
srand(1)
# @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:16))...) for k in 1:M÷K], M)
# @time fast(svec1)
@time radixsort!(svec1) # 4 seconds on 10m; 41 seconds on 100m;
# @code_warntype radixsort!(svec1)
issorted(svec1)

const M=100_000_000; const K=100;
srand(1);
# @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
# @time fast(svec1)
@time radixsort!(svec1) # 22-25-27s seconds
# @code_warntype radixsort!(svec1)
issorted(svec1)

const M=100_000_000; const K=100;
srand(1);
# @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
# @time fast(svec1)
@time FastGroupBy.radixsort8!(svec1) # 25-29-26 seconds slightly slower
# @code_warntype radixsort!(svec1)
issorted(svec1)

const M=200_000_000; const K=100;
srand(1);
# @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
# @time fast(svec1)
@time radixsort!(svec1) # 50 seconds
# @code_warntype radixsort!(svec1)
issorted(svec1)

const M=200_000_000; const K=100;
srand(1);
# @time svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
# @time fast(svec1)
@time FastGroupBy.radixsort8!(svec1) # 25-29-26 seconds slightly slower
# @code_warntype radixsort!(svec1)
issorted(svec1)


# 7seconds on 10million; 2mins on 100m and only 12 seconds in
# srand(1)
# @time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
# @time sort(svec1)

# srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
# @time radixsort!(svec1)
# issorted(length.(svec1))
# issorted(svec1)

# srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
# @time sort(svec1) # takes about 2 mins for 100m

srand(1)
# @time svec1 = rand(["id"*dec(k,rand(1:14)) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:16))...) for k in 1:M÷K], M)
@time radixsort!(svec1)
issorted(svec1)
#
# srand(1)
# @time svec1 = rand(["id"*dec(k,22) for k in 1:M÷K], M)
# @time radixsort!(svec1)
# issorted(svec1)
#
# x = svec1[1:end-1] .> svec1[2:end]
# x = vcat(false, x) .| vcat(x, false)
# (1:length(x))[x]
#
# svec1[9999248:9999249]
#
#
#
# @time svec1 = rand(["id"*dec(k,rand(1:24)) for k in 1:M÷K], M)
# #@time svec1 = ["id"*dec(k,rand(1:22)) for k in 1:M÷K]
# @time sort!(svec1)
# issorted(svec1)


# @time cc = load_bits.(svec1)
# @time sort(cc)
# include("sorttwo2.jl")
# @time sorttwo2!(cc, svec1)

# include("sorttwo2.jl")
const M=100_000_000; const K=100
srand(1)
# @time svec1 = rand(["i"*dec(k,rand(1:7)) for k in 1:M÷K], M)
@time svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
@time lens = maximum(sizeof.(svec1)) # 3-5 econds
iters = ceil(lens/8)
@time cc = load_bits.(svec1) # 9 seconds
ii = [1:length(cc)...]
# @time sorttwo2!(cc, svec1) # 11 seconds
@time sorttwo2!(cc, ii) ## 5 seconds

@time svec1 = svec1[ii]
issorted(svec1)

# return svec
# sort the longest vector using LSD

# skipbytes = 0
# bitsrep = load_bits.(svec)
# sorttwo2!(bitsrep, svec)
# i = 0
# while !issorted(svec)
#     i = i + 1
#     skipbytes += 8
#     if i == 4
#         throw(ErrorException("wassup"))
#     end
#     sorttwo2!(load_bits.(svec, skipbytes), svec)
# end
# return svec
