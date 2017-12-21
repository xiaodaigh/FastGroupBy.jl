using Revise

using RCall

const N = Int(2e8); const K = 100;


R"""
memory.limit(2e9)
library(data.table)
N=$N; K=$K
set.seed(1)
DT <- data.table(
  id1 = sample(sprintf("id%010d",1:(N/K)), N, TRUE),      # large groups (char)
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
df = DataFrame(id_str_large = rand(["id"*dec(k,10) for k = 1:Int(N/K)],N) , val = rand(round.(rand(K)*100,4), N));
x1 = @elapsed sumby!(df, :id_str_large, :val);


# this is way too slow
# id_str_large = rand(["id"*dec(k,10) for k = 1:Int(N/K)],N);
# val = rand(round.(rand(K)*100,4), N);
# x2 = @elapsed fastby!(sum, id_str_large, val)

x
x1
# x2 
x1/parse(Float64, x[1:end-3])