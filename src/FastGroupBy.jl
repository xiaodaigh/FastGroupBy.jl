__precompile__(true)
module FastGroupBy

using SortingAlgorithms, Base.Order, Compat, IndexedTables, DataFrames
import Base: ht_keyindex, rehash!, _setindex!, ht_keyindex2
import SortingAlgorithms: uint_mapping, RADIX_SIZE, RADIX_MASK
import DataFrames: DataFrame, AbstractDataFrame
import IndexedTables: NDSparse, column
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
export sumby_multi_rs, fsortandperm_radix!,sorttwo!,fcollect, grouptwo!

##############################################################################
##
## Load files
##
##############################################################################

include("sumby.jl")
include("sortandperm.jl")
include("sumby_multithreaded.jl")
include("util.jl")

end # module FastGroupBy
