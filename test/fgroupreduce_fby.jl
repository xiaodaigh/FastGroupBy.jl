#######################################################################
# setting up
#######################################################################
# using Revise
using FastGroupBy, BenchmarkTools, SortingLab, CategoricalArrays, Test
using Random

# import Base: getindex, similar, setindex!, size
N = 100_000_000; K = 100
Random.seed!(1);
val = rand(1:5, N);
pool = "id".*lpad.(1:100,3, '0');
fn = sum;

#######################################################################
# convert to CategoricalVector
#######################################################################
y = CategoricalArray{String, 1}(rand(UInt32(1):UInt32(length(pool)), N), CategoricalPool(pool, true));
y = compress(y);
# @benchmark sort($y)

z = CategoricalArray{String, 1}(rand(UInt32(1):UInt32(length(pool)), N), CategoricalPool(pool, true));
z = compress(z);
byveccv = (y, z);
 # 2mins for 2b length vectors


@benchmark fgroupreduce($+, $byveccv, $val) # 7.5 seconds for 2billion
res1 = fgroupreduce(+, byveccv, val)
res1max = fgroupreduce(max, byveccv, val)



@benchmark fby($sum, $byveccv, $val)
res = fby(sum, byveccv, val)
# @code_warntype fby(sum, byveccv, val)


@test all(res[1] .== res1[1])
@test all(res[2] .== res1[2])
@test all(res[3] .== res1[3])

sort!(dfa, cols=[:y, :z])

@test all(dfa[:y] .== res1[1])
@test all(dfa[:z] .== res1[2])
@test all(dfa[:val_sum] .== res1[3])

import FastGroupBy: fgroupreduce
fgroupreduce(fn, df, bysyms::Tuple{Symbol, Symbol}, val::Symbol) = DataFrame([fgroupreduce(fn, (df[bysyms[1]], df[bysyms[2]]), df[val])...], [bysyms..., val])
@time a = fgroupreduce(+, df, (:y, :z), :val)

DataFrame([a...])






if false
    using DataFrames

    df = DataFrame(y = y, z = z, val = val)

    @benchmark aggregate($df, $[:y,:z], $sum)
    # BenchmarkTools.Trial:
    #   memory estimate:  6.28 GiB
    #   allocs estimate:  101028306
    #   --------------
    #   minimum time:     20.904 s (4.59% GC)
    #   median time:      20.904 s (4.59% GC)
    #   mean time:        20.904 s (4.59% GC)
    #   maximum time:     20.904 s (4.59% GC)
    #   --------------
    #   samples:          1
    #   evals/sample:     1

    @benchmark by($df, $[:y,:z], df1->sum(df1[:val]))
    # BenchmarkTools.Trial:
    # memory estimate:  6.25 GiB
    # allocs estimate:  100628265
    # --------------
    # minimum time:     29.894 s (3.82% GC)
    # median time:      29.894 s (3.82% GC)
    # mean time:        29.894 s (3.82% GC)
    # maximum time:     29.894 s (3.82% GC)
    # --------------
    # samples:          1
    # evals/sample:     1

    @benchmark fgroupreduce($+, $byveccv, $val) samples = 5 seconds = 20 # 7.5 seconds for 2billion
    # BenchmarkTools.Trial:
    # memory estimate:  311.27 KiB
    # allocs estimate:  1338
    # --------------
    # minimum time:     366.854 ms (0.00% GC)
    # median time:      387.955 ms (0.00% GC)
    # mean time:        401.369 ms (0.00% GC)
    # maximum time:     443.034 ms (0.00% GC)
    # --------------
    # samples:          13
    # evals/sample:     1

    using IndexedTables, IterableTables
    t = table(df)
    ti = reindex(t,(:y,:z))

    @benchmark IndexedTables.groupreduce(+, ti, (:y,:z), select = :val) samples = 5 seconds = 20
    # BenchmarkTools.Trial:
    # memory estimate:  1.07 MiB
    # allocs estimate:  10243
    # --------------
    # minimum time:     2.465 s (0.00% GC)
    # median time:      2.561 s (0.00% GC)
    # mean time:        2.555 s (0.00% GC)
    # maximum time:     2.660 s (0.00% GC)
    # --------------
    # samples:          5
    # evals/sample:     1

    using RCall

    r_timing = R"""
    memory.limit(2^31-1)
    N=1e8; K=100
    set.seed(1)
    library(data.table)
    DT <- data.table(
    id1 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
    id2 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
    v1 =  sample(5, N, TRUE)                          # int in range [1,5]
    )

    system.time( DT[, sum(v1), keyby="id1,id2"] )
    """
    # RCall.RObject{RCall.RealSxp}
    # user  system elapsed
    # 4.75    0.29    5.12

    r_timing2 = R"""
    setkey(DT, id1, id2)
    system.time( DT[, sum(v1), keyby="id1,id2"])
    """
    # user  system elapsed
    # 1.24    0.07    1.33

    using Plots
    bar(
        ["FastGroupBy.jl", "DataFrames.jl","IndexedTables.jl (indexed)","R data.table", "R data.table (indexed)"],
        [0.401, 20.9, 2.555, r_timing[1], r_timing2[3]],
        title = "Group-by 2 factors with uniques: 100; len: 100m",
        label = "seconds",
        ylabel = "mean run time"
    )
    savefig("Group_by2_cate_perf.png")

end
