# FastGroupBy

Fast algorithms for doing group-by. Currently only `sumby` is implemented

# Faster string sort
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
The speed is now on par with R for strings of size 8 bytes

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

@time using FastGroupBy
@time using DataFrames, IndexedTables, Compat, BenchmarkTools
@time import DataFrames.DataFrame

const N = 10_000_000; const K = 100

srand(1)
@time idt = IndexedTable(
  Columns(row_id = [1:N;]),
  Columns(
    id = rand(1:Int(round(N/K)),N),
    val = rand(round.(rand(K)*100,4), N)
  ));

# sumby is faster for IndexedTables without missings
@belapsed IndexedTables.aggregate_vec(sum, idt, by =(:id,), with = :val)
@belapsed sumby(idt, :id, :val)

# sumby is also faster for DataFrame without missings
srand(1);
@time df = DataFrame(id = rand(1:Int(round(N/K)), N), val = rand(round.(rand(K)*100,4), N));
@belapsed DataFrames.aggregate(df, :id, sum)
@belapsed sumby(df, :id, :val)
```
