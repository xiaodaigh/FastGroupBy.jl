using Revise
using FastGroupBy, BenchmarkTools

using DataFrames, CSV

iris = CSV.read(joinpath(Pkg.dir("DataFrames"), "test/data/iris.csv"));

g(iris) = by(iris, :Species, size)
@time g(iris)
@time fastby(size, iris, :Species)


# using RCall
# R"""
# library(future)
# plan(multiprocess)

# library(data.table)
# library(feather)
# write_feather(rbindlist(future_lapply(list.files("d:/data/fannie_mae/Acquisition_all/",full.names = T), fread)), "d:/fm.feather")
# gc()
# """

# files = readdir("d:/data/fannie_mae/Acquisition_all/")#[rand(1:end, 5)]
# @time fmq3 = CSV.read.("d:/data/fannie_mae/Acquisition_all/".*files, delim='|', rows_for_type_detect = 713316, header=false);
# @time fmq4 = reduce(vcat, fmq3);

# using JLD2, Feather
# Feather.write("d:/data/fm5.feather", fmq4);

# @time fmq4 = Feather.read("d:/fm.feather");
g(fmq4) = aggregate(fmq4[:,[:V20,:V5]], :V20, mean)
@time g(fmq4);
@time fastby(mean, fmq4, :V20, :V5);


const M=100_000_000; const K=100;
srand(1);
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
# using FastGroupBy.radixsort! to sort strings of length 8
y = repeat([1], inner=length(svec1));
@time a = fastby!(sum, svec1, y);

using StatsBase
srand(1);
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M);
@time b = countmap(svec1, alg = :dict);
[a[k]≈ b[k] for k in keys(a)] |> all

srand(1);
x = rand(Bool, 100_000_000);
y = rand(100_000_000);

@time fastby!(sum, x, y)


srand(1);
x = rand(1:1_000_000, 100_000_000);
y = rand(100_000_000);
@time a = fastby!(sum,x,y);

srand(1);
x = rand(1:1_000_000, 100_000_000);
y = rand(100_000_000);
@time a = fastby_check_sorted!(sum,x,y);

@code_warntype
@code_warntype


srand(1);
x = rand(1:1_000_000, 100_000_000);
y = rand(100_000_000);
@time b = sumby_radixsort!(x,y);

[a[k] ≈ b[k] for k in keys(a)] |> all


@time a = fastby!(sum, x,y);
@time ac = countmap(x, weights(y));
[a[k] ≈ ac[k] for k in keys(a)] |> all

srand(1);
x = rand(1:1_000_000, 100_000_000);
y = rand(100_000_000);
@time a = fastby!(x,y) do yy
    mean(yy)
end;

srand(1);
x = rand(1:1_000_000, 100_000_000);
y = rand(100_000_000);
@time a = fastby!(yy -> sizeof.(yy), x, y);

@time a = fastby!(sum, x,y)
@time a = fastby!(mean, x,y)

@time a = fastby!(x, y) do grouped_y
    # you can perform complex caculations here knowing that grouped_y is y grouped by x
    grouped_y[end] - grouped_y[1]
end;

@time a = fastby!(x, y) do grouped_y
    # you can perform complex caculations here knowing that grouped_y is y grouped by x
    grouped_y[end] - grouped_y[1]
end;

# srand(1)
# x = rand(1:1_000_000, 100_000_000)
# y = rand(100_000_000)
# @time a = sumby_radixsort(x,y)


# x,y = rand(1:5,100), rand(100)
# a = fastby!(copy(x),copy(y), sum)
# b = sumby(copy(x),copy(y))

# [abs(a[k1]-b[k1]) < 0.00000000001 for k1 in keys(a)] |> all

# using BenchmarkTools

# function abc()
#     x = rand(1:1_000_000, 100_000_000)
#     y = rand(100_000_000)
#     @elapsed a = fastby!(x,y, sum)
# end

# function abc1()
#     x = rand(1:1_000_000, 100_000_000)
#     y = rand(100_000_000)
#     @elapsed a = fastby!(x,y, sum, Float64)
# end

# function def()
#     x = rand(1:1_000_000, 100_000_000)
#     y = rand(100_000_000)
#     @elapsed b = sumby_radixsort(x,y)
# end

# srand(1)
# aa = [abc() for i = 1:5]

# srand(1)
# bb = [def() for i =1:5]

# srand(1)
# c = [abc1() for i =1:5]

# aa |> mean
# bb |> mean
# c |> mean

# srand(1)
# x = rand(1:1_000_000, 100_000_000)
# y = rand(100_000_000)
# @time a = _fastby!(x,y, sum)

# srand(1)
# x = rand(1:1_000_000, 100_000_000)
# y = rand(100_000_000)
# @time b = sumby_radixsort(x,y)

# @code_warntype fastby!(x,y, sum)

# @code_warntype _fastby!(x,y, sum, Float64)

# srand(1)
# function hihi()
#     x = rand(1:1_000_000, 100_000_000)
#     y = rand(100_000_000)
#     @elapsed a = _fastby!(x,y, [sum, mean])
# end

# srand(1)
# hi = [hihi() for i =1:5]
# mean(hi)
