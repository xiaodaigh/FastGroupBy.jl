using DataFrames, FreqTables, StatsBase, BenchmarkTools
srand(1); x = rand(1:100, 10^6); y = categorical(x); z = string.(x);

using FastGroupBy

@benchmark freqtable($x)
@benchmark fastby(sum, $x, $x |> length |> fcollect)
@benchmark sumby(x, x |> length |> fcollect)
@benchmark countmap($x)

@benchmark freqtable($y)
# @benchmark fastby(sum, $y, $y |> length |> fcollect)
@benchmark sumby(y, y |> length |> fcollect)
@benchmark countmap($y)

@benchmark freqtable($z)
@benchmark fastby(sum, $z, $z |> length |> fcollect)
@benchmark sumby(z, z |> length |> fcollect)
@benchmark countmap($z)


@benchmark by(DataFrame(x = $x), :x, nrow)

@benchmark fastby(sum, DataFrame(x = $x, weight = $x |> length |> fcollect), :x, :weight)


df1 = DataFrame(grps = rand(1:100, 1_000_000), val = rand(1_000_000))
# compute the difference between the number rows in that group and the mean of `val` in that group
res = fastby(val_grouped -> length(val_grouped) - mean(val_grouped), df1, :grps, :val)
# convert to dataframe
resdf = DataFrame(grps = keys(res) |> collect, len_minus_mean_val = values(res) |> collect)


# or use fastby