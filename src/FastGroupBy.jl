__precompile__(true)
module FastGroupBy

using SortingAlgorithms, Base.Order, Compat, IndexedTables, DataFrames
import Base: ht_keyindex, rehash!, _setindex!, ht_keyindex2
import SortingAlgorithms: uint_mapping, RADIX_SIZE, RADIX_MASK
import DataFrames: DataFrame, AbstractDataFrame
import IndexedTables: IndexedTable, column
import PooledArrays.PooledArray
import CategoricalArrays.CategoricalArray
import SplitApplyCombine.groupreduce


# using DataBench
# using ParallelAccelerator

##############################################################################
##
## Dependencies
##
##############################################################################


##############################################################################
##
## Exported methods and types (in addition to everything reexported above)
##
##############################################################################

export meanby, column, sumby, pmeanby, psumby, select, pgroupreduce
export dict_add_reduce, dict_mean_reduce
export sumby_htsize, sumby_contiguous, sumby_dict, sumby_radixgroup
export sumby_radixsort, sumby_sortperm, sumby_lessmem_chain, sumby
export sumby_multi_rs

##############################################################################
##
## Load files
##
##############################################################################

include("meanby.jl")
include("sumby.jl")
include("sumby_multithreaded.jl")
include("sumby_lessmem_chain.jl")
include("util.jl")
include("pgroupreduce.jl")

end # module FastGroupBy
