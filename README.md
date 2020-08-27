# This package is deprecated as the base DataFrames.jl group-by is plenty fast

# FastGroupBy

Faster algorithms for doing vector group-by. This package currently support faster group-bys where the group-by vector is of type `CategoricalVector` or `Vector{T}` for `T<:Union{Integer, Bool, String}`.

## Installation

~~~~{.julia}

# install
Pkg.add("FastGroupBy")
# install latest version
Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")
~~~~~~~~~~~~~




# `fastby` and `fastby!`
The `fastby` and `fastby!` functions allow the user to perform arbitrary computation on a vector (`valvec`) grouped by another vector (`byvec`). Their output format is a `Tuple` where the first element are the distinct groups and the second are the results of applying the function, `fn` on the `valvec` grouped-by `by`, see below for explanation of `fn`, `byvec`, and `valvec`.

The difference between `fastby` and `fastby!` is that `fastby!` may change the input vectors `byvec` and `valvec` whereas `fastby` won't.

Both functions have the same three main arguments, but we shall illustrate using `fastby` only

~~~~{.julia}

fastby(fn, byvec, valvec)
~~~~~~~~~~~~~




* `fn` is a function `fn` to be applied to each by-group of `valvec`
* `byvec` is the vector to group-by
* `valvec` is the vector that `fn` is applied to

For example `fastby(sum, byvec, valvec)` is equivalent to `StatsBase`'s `countmap(byvec, weights(valvec))`. Consider the below

~~~~{.julia}
using FastGroupBy

byvec  = [88, 888, 8, 88, 888, 88]
valvec = [1 , 2  , 3, 4 , 5  , 6]
~~~~~~~~~~~~~


~~~~
6-element Array{Int64,1}:
 1
 2
 3
 4
 5
 6
~~~~




to compute the sum value of `valvec` in each group of `byvec` we do
~~~~{.julia}
grpsum = fastby(sum, byvec, valvec)
expected_result = Dict(88 => 11, 8 => 3, 888 => 7)
Dict(zip(grpsum...)) == expected_result # true
~~~~~~~~~~~~~


~~~~
true
~~~~





## `fastby!` with an arbitrary `fn`
You can also compute arbitrary functions for each by-group e.g. `mean`
~~~~{.julia}
using Statistics: mean
@time a = fastby(mean, byvec, valvec)
~~~~~~~~~~~~~


~~~~
0.000657 seconds (24 allocations: 1.502 MiB)
([8, 88, 888], [3.0, 3.6666666666666665, 3.5])
~~~~





This generalizes to arbitrary user-defined functions e.g. the below computes the `sizeof` each element within each by group
~~~~{.julia}
byvec  = [88   , 888  , 8  , 88  , 888 , 88]
valvec = ["abc", "def", "g", "hi", "jk", "lmop"]
@time a = fastby(yy -> sizeof.(yy), byvec, valvec);
~~~~~~~~~~~~~


~~~~
0.290550 seconds (280.04 k allocations: 14.957 MiB)
~~~~





Julia's do-notation can be used
~~~~{.julia}
@time a = fastby(byvec, valvec) do grouped_y
    # you can perform complex calculations here knowing that grouped_y is y grouped by x
    grouped_y[end] * grouped_y[1]
end;
~~~~~~~~~~~~~


~~~~
0.172302 seconds (194.41 k allocations: 10.657 MiB)
~~~~





The `fastby` is fast if group by a vector of `Bool`'s as well
~~~~{.julia}
using Random
Random.seed!(1)
x = rand(Bool, 100_000_000);
y = rand(100_000_000);

@time fastby(sum, x, y)
~~~~~~~~~~~~~


~~~~
3.132733 seconds (37 allocations: 774.866 MiB, 6.21% gc time)
(Bool[1, 0], [2.499741155973099e7, 2.5003502408479996e7])
~~~~





The `fastby` works on `String` type as well but is still slower than `countmap` and uses MUCH more RAM and therefore is **NOT recommended (at this stage)**.
~~~~{.julia}
using Random
const M=10_000_000; const K=100;
Random.seed!(1)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
y = repeat([1], inner=length(svec1));
@time a = fastby!(sum, svec1, y);
~~~~~~~~~~~~~


~~~~
4.704647 seconds (491.16 k allocations: 912.926 MiB, 24.89% gc time)
~~~~



~~~~{.julia}

a_dict = Dict(zip(a...))

using StatsBase
@time b = countmap(svec1, alg = :dict);
~~~~~~~~~~~~~


~~~~
1.523348 seconds (48 allocations: 5.670 MiB)
~~~~



~~~~{.julia}
a_dict == b #true
~~~~~~~~~~~~~


~~~~
true
~~~~





## `fastby` on `DataFrames`
One can also apply `fastby` on `DataFrame` by supplying the DataFrame as the second argument and its columns using `Symbol` in the third and fourth argument, being `bycol` and `valcol` respectively. For example

~~~~{.julia}
using DataFrames

df1 = DataFrame(grps = rand(1:100, 1_000_000), val = rand(1_000_000))
# compute the difference between the number rows in that group and the mean of `val` in that group
res = fastby(val_grouped -> length(val_grouped) - mean(val_grouped), df1, :grps, :val)
~~~~~~~~~~~~~


~~~~
100×2 DataFrame
│ Row │ grps  │ V1      │
│     │ Int64 │ Float64 │
├─────┼───────┼─────────┤
│ 1   │ 1     │ 10062.5 │
│ 2   │ 2     │ 9956.5  │
│ 3   │ 3     │ 10026.5 │
│ 4   │ 4     │ 9953.5  │
│ 5   │ 5     │ 9855.5  │
│ 6   │ 6     │ 10019.5 │
│ 7   │ 7     │ 10065.5 │
⋮
│ 93  │ 93    │ 9968.5  │
│ 94  │ 94    │ 10096.5 │
│ 95  │ 95    │ 10008.5 │
│ 96  │ 96    │ 10037.5 │
│ 97  │ 97    │ 9885.5  │
│ 98  │ 98    │ 10019.5 │
│ 99  │ 99    │ 9937.5  │
│ 100 │ 100   │ 10058.5 │
~~~~


