using RCall
R"""
memory.limit(40000)
require(data.table)
N=1e7; K=100
set.seed(1)
DT <- data.table(
  id1 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
  id2 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
  id3 = sample(sprintf("id%010d",1:(N/K)), N, TRUE), # small groups (char)
  id4 = sample(K, N, TRUE),                          # large groups (int)
  id5 = sample(K, N, TRUE),                          # large groups (int)
  id6 = sample(N/K, N, TRUE),                        # small groups (int)
  v1 =  sample(5, N, TRUE),                          # int in range [1,5]
  v2 =  sample(5, N, TRUE),                          # int in range [1,5]
  v3 =  sample(round(runif(100,max=100),4), N, TRUE) # numeric e.g. 23.5749
)
# fwrite(DT,"DT.csv")
cat("GB =", round(sum(gc()[,2])/1024, 3), "\n")
system.time( DT[, sum(v1), keyby="id1,id2"] )
"""

using DataBench, DataFrames, CSV, TextParse, IterableTables
# df = DataBench.createSynDataFrame(10_000_000, 100)
# @time df = CSV.read("DT.csv");
@time df = TextParse.csvread("DT.csv");
df = DataFrame(df)



fn = sum
byvec = [:id1, :id2]
@time ids = fastby(sum, df, byvec);

aggrb(df) = aggregate(df[[:id1,:id2,:v1]], [:id1,:id2], sum);

using BenchmarkTools
@btime aggrb($df)
@time by(df[[:id1,:id2,:v1]], [:id1,:id2], subdf -> sum(subdf[:v1]));
@time by(df, [:id1,:id2], subdf -> sum(subdf[:v1]));


using FastGroupBy
@time fastby(sum, df, :id1, :v1);

showcols(df)


using SortingAlgorithms
using DataStructures
idstrvec = rand("id".*dec.(1:1_000_000,10), 100_000_000)

using FastGroupBy
@time fastby(sum, idstrvec, fcollect(length(idstrvec)))


sort(idstrvec[1:10])            # compile
@time sort(idstrvec)
#  80.119106 seconds (88 allocations: 1.118 GiB, 5.72% gc time)

"Return `key=>count` pairs for elements in the argument sorted by the `key`."
function sorted_counts(v)
    c = counter(v)
    sort(collect(c.map), by = first)
end
using SortingAlgorithms
sorted_counts(idstrvec[1:10])   # compile
@time sorted_counts(idstrvec)
# 49.105053 seconds (1.00 M allocations: 114.762 MiB, 0.35% gc time)


