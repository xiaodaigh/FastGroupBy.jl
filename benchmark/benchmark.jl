using FastGroupBy, DataFrames, IndexedTables, IterableTables, SplitApplyCombine
import DataFrames.DataFrame
import Base.ht_keyindex

srand(1);
const N = Int64(2e9/8)
const K = 100

id4 = rand(1:K,N)
v1 = rand(1:5,N)

@time aa1 = sumby(id4, v1)
@time aa1 = sumby(id4, v1)

using DataBench
@time df = DataBench.createIndexedTable(N, 100)
@elapsed groupreduce(
    x->x[1],
    x->(x[2],x[3],x[4]),
    (x,y)->(x[1]+y[1],x[2]+y[2],x[3]+y[3]),
    zip(column(df,:id6),column(df,:v1),column(df,:v2),column(df,:v3)))


addprocs(4)
@everywhere using FastGroupBy
@time aa1 = sumby(df, :id4, :v1)
@time aa = psumby(df, :id4, :v1)

@time aa1 = sumby(df, :id6, :v1);
@time aa = psumby(df, :id6, :v1);

@time aa1 = sumby(df, :id6, :v3);
@time aa = psumby(df, :id6, :v3);

@time aa2 = reduce(vcat, [DataFrame(id6=collect(keys(aaa)), v3=collect(values(aaa))) for aaa = aa])
@time aa3 = sumby(aa2,:id6,:v3)
@time DataFrame(id6=collect(keys(aa3)), v3=values(aa3))

# DataFrames is faster at dealing with DataArrays especially after first compilation
@time meanby(df, :id, :val)
@time meanby(df, :id, :val)
@time DataFrames.aggregate(df, :id, mean)
@time DataFrames.aggregate(df, :id, mean)

srand(1)
@time idt = IndexedTable(
  Columns(row_id = [1:N;]),
  Columns(
    id = rand(1:K,N),
    val = rand(round.(rand(K)*100,4), N)
  ));

# meanby is faster for IndexedTables without nulls
@time meanby(idt, :id, :val)
@time meanby(idt, :id, :val)
@time IndexedTables.aggregate_vec(mean, idt, by =(:id,), with = :val)
@time IndexedTables.aggregate_vec(mean, idt, by =(:id,), with = :val)

# meanby is also faster for DataFrame without nulls
@time idtdf = DataFrame(idt)
@time meanby(idtdf, :id, :val)
@time meanby(idtdf, :id, :val)
@time DataFrames.aggregate(idtdf, :id, mean)
@time DataFrames.aggregate(idtdf, :id, mean)
