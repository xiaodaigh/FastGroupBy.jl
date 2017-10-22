using FastGroupBy, DataFrames, IndexedTables, IterableTables
import DataFrames.DataFrame

srand(1);
const N = 10_000_000
const K = 100

@time df = DataFrame(id = rand(1:K,N), val = rand(round.(rand(K)*100,4), N))
# DataFrames is faster at dealing with DataArrays especially after first compilation
@time DataFrames.aggregate(df, :id, mean)
@time DataFrames.aggregate(df, :id, mean)
@time meanby(df, :id, :val)
@time meanby(df, :id, :val)

srand(1)
@time idt = IndexedTable(
  Columns(row_id = [1:N;]),
  Columns(
    id = rand(1:K,N),
    val = rand(round.(rand(K)*100,4), N)
  ));

# meanby is faster for IndexedTables without nulls
@time IndexedTables.aggregate_vec(mean, idt, by =(:id,), with = :val)
@time IndexedTables.aggregate_vec(mean, idt, by =(:id,), with = :val)
@time meanby(idt, :id, :val)
@time meanby(idt, :id, :val)

# meanby is also faster for DataFrame without nulls
@time idtdf = DataFrame(idt)
@time DataFrames.aggregate(idtdf, :id, mean)
@time DataFrames.aggregate(idtdf, :id, mean)
@time meanby(idtdf, :id, :val)
@time meanby(idtdf, :id, :val)
