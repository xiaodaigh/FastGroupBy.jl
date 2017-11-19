# FastGroupBy

Fast algorithms for doing group-by. Currently only `sumby` is implemented

```julia
# install SplitApplyCombine.jl
Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git")

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
