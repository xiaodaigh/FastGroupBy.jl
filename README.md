# FastGroupBy

Faster algorithms for doing vector group-by. You can install it using

```julia
# install
Pkg.add("FastGroupBy")
# install latest version
# `fastby` is not yet published so need to clone
Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")
```
**Note: `fastby` is not yet published and hence need to manual install with `Pkg.clone`**

# `fastby` and `fastby!`
The `fastby` and `fastby!` functions allow the user to perform arbitrary computation on a vector (`valvec`) grouped by another vector (`byvec`). Their output format is a `Dict` whose `Dict`-keys are the distinct groups and the `Dict`-values are the results of applying the function, `fn` on the `valvec`, see below for explanation of `fn`, `byvec`, and `valvec`.

The difference between `fastby` and `fastby!` is that `fastby!` may change the input vectors `byvec` and `valvec` whereas `fastby` won't.

Both functions have the same three main arguments, but we shall illustrate using `fastby` only

```julia
fastby(fn, byvec, valvec)
```

* `fn` is a function `fn` to be applied to each by-group of `valvec`
* `byvec` is the vector to group by; `eltype(byvec)` must be one of these `Bool, Int8, Int16, Int32, Int64, Int128,
                                     UInt8, UInt16, UInt32, UInt64, UInt128, String`
* `valvec` is the vector that `fn` is applied to

For example `fastby(sum, byvec, valvec)` is equivalent to `StatsBase`'s `countmap(byvec, weights(valvec))`. Consider the below
```julia
byvec  = [88, 888, 8, 88, 888, 88]
valvec = [1 , 2  , 3, 4 , 5  , 6]
```
to compute the sum value of `valvec` in each group of `byvec` we do
```julia
grpsum = fastby(sum, byvec, valvec)
expected_result = Dict(88 => 11, 8 => 3, 888 => 7)
grpsum == expected_result # true
```

## `fastby!` with an arbitrary `fn`
You can also compute arbitrary functions for each by-group e.g. `mean`
```julia
@time a = fastby(mean, x, y)
```

This generalizes to arbitrary user-defined functions e.g. the below computes the `sizeof` each element within each by group
```julia
byvec  = [88   , 888  , 8  , 88  , 888 , 88]
valvec = ["abc", "def", "g", "hi", "jk", "lmop"]
@time a = fastby(yy -> sizeof.(yy), x, y);
```

Julia's do-notation can be used
```julia
@time a = fastby(x, y) do grouped_y
    # you can perform complex caculations here knowing that grouped_y is y grouped by x
    grouped_y[end] - grouped_y[1]
end;
```

The `fastby` is fast if group by a vector of `Bool`'s as well
```julia
using Random
Random.seed!(1)
x = rand(Bool, 100_000_000);
y = rand(100_000_000);

@time fastby(sum, x, y)
```

The `fastby` works on `String` type as well but is still slower than `countmap` and uses MUCH more RAM and therefore is **NOT recommended (at this stage)**.
```julia
using Random
const M=10_000_000; const K=100;
Random.seed!(1)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
y = repeat([1], inner=length(svec1));
@time a = fastby!(sum, svec1, y);

a_dict = Dict(zip(a...))

using StatsBase
@time b = countmap(svec1, alg = :dict);
a_dict == b #true
```

## `fastby` on `DataFrames`
One can also apply `fastby` on `DataFrame` by supplying the DataFrame as the second argument and its columns using `Symbol` in the third and fourth argument, being `bycol` and `valcol` respectively. For example

```julia
df1 = DataFrame(grps = rand(1:100, 1_000_000), val = rand(1_000_000))
# compute the difference between the number rows in that group and the mean of `val` in that group
res = fastby(val_grouped -> length(val_grouped) - mean(val_grouped), df1, :grps, :val)
# convert to dataframe
resdf = DataFrame(grps = keys(res) |> collect, len_minus_mean_val = values(res) |> collect)
```
