using Compat
import Base: Forward
import SortingAlgorithms: RADIX_MASK, RADIX_SIZE, uint_mapping
using FastGroupBy
using BenchmarkTools

using SortingAlgorithms, Base.Order, Compat, IndexedTables, DataFrames
import Base: ht_keyindex, rehash!, _setindex!
import SortingAlgorithms: uint_mapping, RADIX_SIZE, RADIX_MASK
import DataFrames: DataFrame, AbstractDataFrame
import IndexedTables: IndexedTable, column
import PooledArrays.PooledArray
import CategoricalArrays.CategoricalArray
import SplitApplyCombine.groupreduce

using StatsBase

T = Int
S = Int

N  = 1_000_000;
K = 100;
by = nothing;
val = nothing;
gc();
srand(1);
by = rand(Int32(1):Int32(round(N/K)), N);
val = rand(Int32(1):Int32(5), N)

#
# @time sumby_lessmem_chain(by, val);
#
# by = nothing;
# val = nothing;
# gc();
# srand(1);
# @time val = rand(Int32(1):Int32(5), N);
# @time by = rand(Int32(1):Int32(round(N/K)), N);
# @time sumby(by, val);
#
# function abc()
#   by1, val1 = copy(by), copy(val)
#   @elapsed sumby_lessmem_chain(by1, val1)
# end
#
# function def()
#   by1, val1 = copy(by), copy(val)
#   @elapsed sumby(by1, val1)
# end

# a1 = mean([abc() for i = 1:5][2:end])
# b1 = mean([def() for i = 1:5][2:end])
# 1 - a1/b1
2+2
