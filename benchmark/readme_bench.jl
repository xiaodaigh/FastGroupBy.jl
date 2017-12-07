@time using FastGroupBy
@time using DataFrames, IndexedTables, Compat, BenchmarkTools, Missings
@time import DataFrames.DataFrame

const N = 10_000_000
const K = 100
srand(1)
@time idt = IndexedTable(
  Columns(row_id = [1:N;]),
  Columns(
    id = rand(1:Int(round(N/K)),N),
    id4 = rand(1:K,N),
    val = rand(round.(rand(K)*100,4), N)
  ));

# sumby is faster for IndexedTables without missings
@belapsed IndexedTables.aggregate_vec(sum, idt, by =(:id,), with = :val)
@belapsed sumby(idt, :id, :val)

@belapsed IndexedTables.aggregate_vec(sum, idt, by =(:id4,), with = :val)
@belapsed sumby(idt, :id4, :val)

# sumby is also faster for DataFrame without missings
srand(1);
@time df = DataFrame(
    id = rand(1:Int(round(N/K)), N),
    id4 = rand(1:K,N),
    val = rand(round.(rand(K)*100,4), N));
@belapsed DataFrames.aggregate(df, :id, sum)
@belapsed sumby(df, :id, :val)

@belapsed DataFrames.aggregate(df, :id4, sum)
@belapsed sumby(df, :id4, :val)

# generate with missing
# srand(1)
# @time idt_missing = IndexedTable(
#   Columns(row_id = [1:N;]),
#   Columns(
#     id = rand([collect(1:Int(round(N/K)))..., missing],N),
#     val = rand(round.(rand(K)*100,4), N)
#   ));
#
# # sumby is faster for IndexedTables without missings
# @belapsed IndexedTables.aggregate_vec(sum, idt_missing, by =(:id,), with = :val)
# @belapsed sumby(idt_missing, :id, :val)
