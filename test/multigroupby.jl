# fastby multi
tic()
#######################################################################
# setting up
#######################################################################
using Revise
using FastGroupBy, DataFrames, BenchmarkTools, SortingLab, ShortStrings
# import Base: getindex, similar, setindex!, size
N = 100_000_000; K = 100
srand(1);
# val = rand(round.(rand(K)*100,4), N);
val = rand(1:5, N);
pool = "id".*dec.(1:100,3);
df = DataFrame(id1 = rand(pool,N), id2 = rand(pool,N), val = val);
byvec = ([df[:id1], df[:id2]]...);
# valvec = val;
fn = sum;

#######################################################################
# convert to ShortStrings
#######################################################################
# normal sort is twice as slow
x = byvec[1] .|> ShorterString;
@benchmark sort($x, by = x->x.size_content)
# BenchmarkTools.Trial:
#   memory estimate:  114.44 MiB
#   allocs estimate:  11
#   --------------
#   minimum time:     594.169 ms (0.11% GC)
#   median time:      1.026 s (41.83% GC)
#   mean time:        905.181 ms (32.13% GC)
#   maximum time:     1.120 s (39.28% GC)
#   --------------
#   samples:          6
#   evals/sample:     1

using SortingAlgorithms
@benchmark sort($x, by = x->x.size_content, alg=RadixSort)
# BenchmarkTools.Trial:
#   memory estimate:  154.59 MiB
#   allocs estimate:  26
#   --------------
#   minimum time:     187.913 ms (0.90% GC)
#   median time:      695.344 ms (72.81% GC)
#   mean time:        608.867 ms (66.90% GC)
#   maximum time:     768.958 ms (72.30% GC)
#   --------------
#   samples:          9
#   evals/sample:     1

x1 = (x->x.size_content).(x)
@benchmark sort(x1, alg=RadixSort) # roughly the same as the by version above

@time sort!(x1, alg= RadixSort)
@time maximum(sizeof, x)
@time minimum(sizeof, x)

byvecss = (ShorterString.(byvec[1]), ShorterString.(byvec[2]))

SortingLab.uint_mapping(o, s::ShorterString) = s.size_content
SortingLab.uint_mapping(o, s::ShortString) = s.size_content


function SortingLab.uint_hist(bits::Vector{ShorterString}, RADIX_SIZE = 16, RADIX_MASK = 0xffff)
    SortingLab.uint_hist(SortingLab.uint_mapping.(Base.Forward, bits))
end

function shortstring_groupby(byvecss, val)
    x1 = copy(byvecss[1]);
    vi = FastGroupBy.ValIndexVector(val, x1);

    x2 = copy(byvecss[2]);
    @time SortingLab.sorttwo!(x2, vi)
    vi
end

@time shortstring_groupby(byvecss, val)
function shortstring_groupby_msd!(byvecss, val)
    vi = FastGroupBy.ValIndexVector(byvecss[2], val);
    @time SortingLab.sorttwo!(byvecss[1], vi)
    vi
end
shortstring_groupby_msd!(byvecss, val)

@benchmark shortstring_groupby_msd!($byvecss, $val)




#######################################################################
# FastGroupBy
# too slow
#######################################################################
@time y1 = FastGroupBy.fastby1(fn, byvec, valvec); # 4.5s 10m
@time y2 = FastGroupBy.fastby2(fn, byvec, valvec); # 4.5s 10m

index = fcollect(length(byvec[1]))

@benchmark grouptwo!($(byvec[1]), $index)

@benchmark radixsort($(byvec[1]))

using SortingLab
@time fsortperm(byvec[1])
@benchmark radixsort($(byvec[1]))

function grp2(v)
    cv = copy(v)
    i = fcollect(length(cv))
    grouptwo!(cv, i)
end
@benchmark grp2(byvec[2])
@code_warntype grp2(byvec[2])



#######################################################################
# Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git")
# using SplitApplyCombine
#######################################################################

import Base: ht_keyindex2!

function sac(fn, byvec, valvec::Vector{T}) where T
    cm = Dict{Tuple{eltype.(byvec)...}, T}()
    for i = 1:length(valvec)
        v = Tuple(bv[i] for bv in byvec)
        index = ht_keyindex2!(cm, v)
        if index > 0
            @inbounds cm.vals[index] += valvec[i]
        else
            @inbounds Base._setindex!(cm, valvec[i], v, -index)
        end
    end
    l = length(cm)

    # bvout = Tuple(Vector{eltype(bv)}(l) for bv in byvec)
    # for (i, c) in enumerate(keys(cm))
    #     for j in 1:length(c)
    #         bvout[j][i] = c[j]
    #     end
    # end
    # (bvout, values(cm))
end

@benchmark sac($byvec, $valvec)

# @code_warntype sac(sum, byvec, valvec)
res = sac(sum, byvec, valvec)

# byvec = [:id1,:id2]
# valvec = setdiff(names(df), byvec)
# @time y = fastby(fn, df, byvec, :val); # 0.4
# @code_warntype fastby(fn, df, byvec, :val)
@time x = DataFrames.aggregate(df[1,:], [:id1,:id2], sum); # test
@benchmark x = DataFrames.aggregate($df, [:id1,:id2], sum)

using JuliaDB

@time t = table(df[:id1], df[:id2], df[:val], names = [:id1, :id2, :val]);
@time groupreduce(+, t, (:id1,:id2), select = :val)
@time IndexedTables.groupby(sum, t, (:id1,:id2), select = :val)

@time t1 = reindex(t, (:id1,:id2), :val);
@benchmark groupreduce(+, t1, (:id1,:id2), select = :val);
@benchmark IndexedTables.groupby(sum, t1, (:id1,:id2), select = :val);


# @time IndexedTables.summarize(+, t, (:id1,:id2), select = :val)


ti = table(df[:id1], df[:id2], df[:val], names = [:id1, :id2, :val], pkey=(:id1, :id2))
@benchmark groupreduce(+, ti, (:id1,:id2), select = :val)
@benchmark IndexedTables.groupby(sum, ti, (:id1,:id2), select = :val)


using RCall
@rput df
R"""
library(data.table)
setDT(df)
system.time(df[,sum(val), keyby="id1,id2"])
"""

R"""
library(data.table)
setDT(df)
setkey(df, id1, id2)
system.time(df[,sum(val), keyby="id1,id2"])
"""

@rput df
R"""
library(data.table)
setDT(df)
df[,id1:=as.factor(id1)]
df[,id2:=as.factor(id2)]
system.time(df[,sum(val), keyby="id1,id2"])
""" # 0.45 10m

@rput df
R"""
library(data.table)
setDT(df)
df[,id1:=as.factor(id1)]
df[,id2:=as.factor(id2)]
setkey(df, id1, id2)
system.time(df[,sum(val), keyby="id1,id2"])
""" # 0.45 10m

#######################################################################
# setting up
#######################################################################
using Revise
using FastGroupBy, DataFrames, BenchmarkTools, SortingLab, ShortStrings
using SortingAlgorithms
N = 100_000_000; K = 100
srand(1);
r = rand(1:N÷K, N)

@time sortperm(r, alg=RadixSort)

a = rand(rand(Float64, N÷K), N)
@time sort(a)
@time sort(a, alg = RadixSort)

@time fsort(a)

rr = "id".*dec.(1:N÷K, 10)
r = rand(rr, N)

@benchmark fsort($r) samples = 5 seconds = 120
@benchmark fsort($r, false, (11, 0x007ff)) samples = 5 seconds = 120




@time radixsort(r)
@time fsort(r, (11, 0x007ff))

@benchmark fsort($r) samples = 5 seconds = 120
@benchmark fsort($r, (11, 0x007ff)) samples = 5 seconds = 120
@benchmark fsort($r, (13, 0x00001fff)) samples = 5 seconds = 120
@benchmark fsort($r, (22, 0x003fffff)) samples = 5 seconds = 120

@benchmark sort($r, alg=RadixSort)
@benchmark sort($r)




rr = rand(1:Int(N÷2), N)
rr1 = rand(1:Int(N÷2)-1, N)
@time sort(rr)
@time sort(rr1)

using SortingAlgorithms
@benchmark sortperm($r)
@benchmark sortperm($r, alg = RadixSort)

rs = [randstring(8) for i = 1:1_000_000]
rs1 = rand(rs, 100_000_000)

aa(s) = (s |> pointer |> Ptr{UInt32} |> unsafe_load) >> 16

@time sort(rs1, by = aa);
@time radixsort(rs1);
@time SortingLab.fsort(rs1, radix)


radix_opts = (16, 0xffff)


Base.sort!(rs1)

ordr = Base.ord(isless, identity, false, Base.Forward)

using SortingLab, FastGroupBy

function sortandperm!(v::Vector{Int64})
    a = collect(1:length(v))
    SortingLab.sorttwo!(v, a)
    return (v,a)
end

sortandperm(v) = sortandperm!(copy(v))

@benchmark sortandperm(r)
issorted(r)

function sortandperm2!(v::Vector{Int64})
    a = fcollect(length(v))
    SortingLab.sorttwo!(v, a)
    return (v,a)
end

sortandperm2(v) = sortandperm2!(copy(v))

@benchmark sortandperm2($r)

function fsortperm(v)
    @time a = collect(UInt32(1):UInt32(length(v)))
    @time v1 .= (v .<< 32) .| a
    @time SortingLab.sort32!(v1)
    @time v1 .= ((v .>> 32) .<< 32) .| ((v1 .<< 32) .>> 32)
    @time SortingLab.sort32!(v1)
    @time v1 .& 0xffffffff
end

@time fsortperm(r);

@benchmark fsortperm($r)

a = fsortperm(r)
issorted(r[a])



cv = copy(r)
r_sorted, r_perm = sortandperm!(r)
issorted(r_sorted)
issorted(cv[r_perm])


v = r
min, max = extrema(v)
(diff, o1) = Base.sub_with_overflow(max, min)
(rangelen, o2) = Base.add_with_overflow(diff, oneunit(diff))
if !o1 && !o2 && rangelen < div(n,2)
    return sort_int_range!(v, rangelen, min)
end
