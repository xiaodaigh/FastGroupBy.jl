using Revise

using RCall
using FastGroupBy, BenchmarkTools, DataFrames

const N = Int(1e8); const K = 100;


R"""
memory.limit(2e9)
library(data.table)
N=$N; K=$K
set.seed(1)
DT <- data.table(
  id5 = sample(K, N, TRUE),                          # large groups (int)
  id6 = sample(N/K, N, TRUE),                        # small groups (int)
  v3 =  sample(round(runif(100,max=100),4), N, TRUE) # numeric e.g. 23.5749
)
cat("GB =", round(sum(gc()[,2])/1024, 3), "\n")
pt = proc.time()
DT[, sum(v3), keyby=id5]
x = timetaken(pt); pt = proc.time()
DT[, sum(v3), keyby=id6]
y = timetaken(pt)
rm(DT); gc()
"""

@rget x;
@rget y;


srand(1);
df = DataFrame(id = rand(Int32(1):Int32(round(N/K)), N), id_small = rand(Int8(1):Int8(K),N), val = rand(round.(rand(K)*100,4), N));
x1 = @elapsed sumby!(df, :id_small, :val);

df = nothing; gc()
srand(1);
df = DataFrame(id = rand(Int32(1):Int32(round(N/K)), N), id_small = rand(Int8(1):Int8(K),N), val = rand(round.(rand(K)*100,4), N));
y1 = @elapsed sumby!(df, :id, :val);

df = nothing; gc();
srand(1);
id = rand(Int32(1):Int32(round(N/K)), N);
val = rand(round.(rand(K)*100,4), N);
y2 = @elapsed fastby!(sum, id, val);

y
y1
y2

x1/parse(Float64, x[1:end-3])
y1/parse(Float64, y[1:end-3])
y2/parse(Float64, y[1:end-3])


