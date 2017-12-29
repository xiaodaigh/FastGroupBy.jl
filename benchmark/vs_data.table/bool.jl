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
  id_bool = sample(K, N, TRUE),                      # bool
  v3 =  sample(round(runif(100,max=100),4), N, TRUE) # numeric e.g. 23.5749
)
cat("GB =", round(sum(gc()[,2])/1024, 3), "\n")
pt = proc.time()
DT[, sum(v3), keyby=id_bool]
y = timetaken(pt)
rm(DT); gc()
"""

@rget y;

srand(1);
id_bool = rand(Bool, N);
val = rand(round.(rand(K)*100,4), N);
y1 = @elapsed fastby!(sum, id_bool, val);

y
y1

r_speed = parse(Float64, y[1:end-3])

fgb_speed = y1/parse(Float64, y[1:end-3])

srand(1);
using StatsBase;
id_bool = rand(Bool, N);
val = rand(round.(rand(K)*100,4), N);
y2 = @elapsed countmap(id_bool, weights(val));

cm_speed = y2/parse(Float64, y[1:end-3])


using Plots
bar([1, fgb_speed, cm_speed], title = "Bool fastby! Speed",
xaxis = (""))
hline!(1)