using Revise

using RCall

const N = Int(1e7); const K = 100;


R"""
memory.limit(2e9)
library(data.table)
N=$N; K=$K
set.seed(1)
DT <- data.table(
  id1 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
  v3 =  sample(round(runif(100,max=100),4), N, TRUE) # numeric e.g. 23.5749
)
cat("GB =", round(sum(gc()[,2])/1024, 3), "\n")
pt = proc.time()
DT[, sum(v3), keyby=id1]
x = timetaken(pt)
rm(DT); gc()
"""

@rget x;

using FastGroupBy, BenchmarkTools, DataFrames

srand(1);
df = DataFrame(id_str_small = rand(["id"*dec(k,3) for k = 1:K],N) , val = rand(round.(rand(K)*100,4), N));
x1 = @elapsed sumby!(df, :id_str_small, :val);

x1/parse(Float64, x[1:end-3])


