# FastGroupBy

Faster algorithms for doing vector group-by.

# `fastby!`
The `fastby!` function allows the user to group by a vector and produce 
a `Dict` as the output. 

The function has three main arguments

```julia
fastby!(fn, byvec, valvec)
```

* `fn` is a function `fn` to be applied to eacj by-group of `valvec`
* `byvec` is the vector to group by; `eltype(byvec)` must be one of these `Bool, Int8, Int16, Int32, Int64, Int128,
                                     UInt8, UInt16, UInt32, UInt64, UInt128, String`
* `valvec` is the vector that `fn` is applied to

For example `fastby!(sum, byvec, valvec)` is equivalent to `StatsBase`'s `countmap(byvec, weights(valvec))`. Consider the below
```julia
byvec  = [88, 888, 8, 88, 888, 88]
valvec = [1 , 2  , 3, 4 , 5  , 6]
```
to compute the sum value of `valvec` in each group of `byvec` we do
```julia
grpsum = fastby!(sum, byvec, valvec)
expected_result = Dict(88 => 11, 8 => 3, 888 => 7)
grpsum == expected_result # true
```

## `fastby!` with an arbitrary `fn`
You can also compute arbitrary functions for each by-group e.g. `mean`
```julia
@time a = fastby!(mean, x, y)
```

This generalizes to arbitrary user-defined functions e.g. the below computes the `sizeof` each element within each by group
```julia
byvec  = [88   , 888  , 8  , 88  , 888 , 88]
valvec = ["abc", "def", "g", "hi", "jk", "lmop"]
@time a = fastby!(yy -> sizeof.(yy), x, y);
```

Julia's do-notation can be used
```julia
@time a = fastby!(x, y) do grouped_y
    # you can perform complex caculations here knowing that grouped_y is y grouped by x
    grouped_y[end] - grouped_y[1]
end;
```

The `fastby!` is fast if group by a vector of `Bool`'s as well
```julia
srand(1);
x = rand(Bool, 100_000_000);
y = rand(100_000_000);

@time fastby!(sum, x, y)
```

The `fastby!` works on `String` type as well but is still slower than `countmap` and uses MUCH more RAM and therefore is NOT recommended (at this stage).
```julia
const M=10_000_000; const K=100;
srand(1);
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
y = repeat([1], inner=length(svec1));
@time a = fastby!(sum, svec1, y);

using StatsBase
@time b = countmap(svec1, alg = :dict);
[a[k] ≈ b[k] for k in keys(a)] |> all # true
```

# Faster string sort (in limited cases)
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
svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
@time radixsort!(svec1) #13 seconds
issorted(svec1)
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

# sumby!
The `sumby!` is a special case of `fastby!` in fact its results are the the same as `fastby!(sum, etc1, etc2)`. It is slightly faster than `fastby!`. 

```julia
# install FastGroupBy.jl
# Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")
Pkg.add("FastGroupBy")

using FastGroupBy
using DataFrames, IndexedTables, Compat, BenchmarkTools
import DataFrames.DataFrame

const N = 10_000_000; const K = 100

# `sumby!` is faster than `DataFrame.aggregate`
srand(1);
id = rand(1:Int(round(N/K)), N);
val = rand(round.(rand(K)*100,4), N);
df = DataFrame(id = id, val = val);
@time x = DataFrames.aggregate(df, :id, sum); # 3.3 seconds
@time y = sumby!(df, :id, :val); # 0.4
xdict = Dict(zip(x[:id],x[:val_sum]))
length(xdict) == length(y) && [xdict[k] ≈ y[k] for k in keys(xdict)] |> all
```
