# FastGroupBy

Fast algorithms for doing group-by. Currently only `sumby` is implemented

```julia
# install SplitApplyCombine.jl
Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git") 

# install FastGroupBy.jl
Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")

@time using FastGroupBy
@time using DataFrames, IndexedTables, IterableTables
@time import DataFrames.DataFrame

const N = 10_000_000
const K = 100
srand(1)
@time idt = IndexedTable(
  Columns(row_id = [1:N;]),
  Columns(
    id = rand(1:K,N),
    val = rand(round.(rand(K)*100,4), N)
  ));

# sumby is faster for IndexedTables without nulls
@elapsed IndexedTables.aggregate_vec(sum, idt, by =(:id,), with = :val)
@elapsed IndexedTables.aggregate_vec(sum, idt, by =(:id,), with = :val)
@elapsed sumby(idt, :id, :val)
@elapsed sumby(idt, :id, :val)

# sumby is also faster for DataFrame without nulls
@elapsed idtdf = DataFrame(idt)
@elapsed DataFrames.aggregate(idtdf, :id, sum)
@elapsed DataFrames.aggregate(idtdf, :id, sum)
@elapsed sumby(idtdf, :id, :val)
@elapsed sumby(idtdf, :id, :val)

# DataFrames is faster at dealing with DataArrays especially after first compilation
srand(1);
@time df = DataFrame(id = rand(1:K,N), val = rand(round.(rand(K)*100,4), N))
@elapsed DataFrames.aggregate(df, :id, sum)
@elapsed DataFrames.aggregate(df, :id, sum)
@elapsed sumby(df, :id, :val)
@elapsed sumby(df, :id, :val)
```
