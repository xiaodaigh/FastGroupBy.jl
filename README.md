# FastGroupBy

Fast algorithms for doing group-by. Currently only `sumby` is implemented

# Faster string sort
```julia
# Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")
using FastGroupBy

const M=10_000_000; const K=100
srand(1)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
# using FastGroupBy.radixsort! to sort strings of length 8
@time radixsort!(svec1) # 3 seconds on 10m
issorted(svec1)

srand(1)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
# using Base.sort! to sort strings of length 8
@time sort!(svec1) # 7 seconds on 10m

srand(1)
svec1 = rand([string(rand(Char.(32:126), rand(1:16))...) for k in 1:M÷K], M)
# using FastGroupBy.radixsort! to sort strings of length 16
@time radixsort!(svec1) # 4 seconds on 10m
issorted(svec1)

srand(1)
svec1 = rand([string(rand(Char.(32:126), rand(1:16))...) for k in 1:M÷K], M)
# using Base.sort! to sort strings of length 16
@time sort!(svec1) # 8 seconds

```

The speed is now on par with R for strings of size 8 bytes
```julia
using FastGroupBy

const M=100_000_000; const K=100
srand(1)
svec1 = rand(["id"*dec(k,10) for k in 1:M÷K], M)
@time radixsort!(svec1) #18 seconds
issorted(svec1)

#svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
#@time sort!(svec1)
```

```r
N=1e8; K=100
set.seed(1)
library(data.table)
id3 = sample(sprintf("i%07d",1:(N/K)), N, TRUE)
pt = proc.time()
system.time(sort(id3, method="radix"))
data.table::timetaken(pt) # 18.9 seconds
```

# sumby
```julia
# install FastGroupBy.jl
Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")

using FastGroupBy
using DataFrames, IndexedTables, Compat, BenchmarkTools
import DataFrames.DataFrame

const N = 10_000_000; const K = 100

# sumby is also faster for DataFrame without missings
srand(1);
df = DataFrame(id = rand(1:Int(round(N/K)), N), val = rand(round.(rand(K)*100,4), N));
@time DataFrames.aggregate(df, :id, sum) # 3.3 seconds
@time sumby!(df, :id, :val) # 0.4
```