__precompile__(true)
module FastGroupBy

using SortingAlgorithms, Base.Order, Compat, IndexedTables, DataFrames
import Base: ht_keyindex, rehash!, _setindex!, ht_keyindex2
import SortingAlgorithms: uint_mapping, RADIX_SIZE, RADIX_MASK
import DataFrames: DataFrame, AbstractDataFrame
import IndexedTables: NDSparse, column
import PooledArrays.PooledArray
import CategoricalArrays.CategoricalArray
# import SplitApplyCombine.groupreduce


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

export fastby, column, sumby
export sumby_contiguous, sumby_dict, sumby_radixgroup
export sumby_radixsort, sumby_sortperm, sumby
export sumby_multi_rs, fsortandperm_radix!,sorttwo!,fcollect, grouptwo!
export radixsort!

##############################################################################
##
## Load files
##
##############################################################################

include("sumby.jl")
include("sorttwo_lsd.jl")
include("sortandperm.jl")
include("sumby_multithreaded.jl")
include("util.jl")
include("grouptwo.jl")
include("string_radixsort.jl")
include("sorttwo_lsd16.jl")

end # module FastGroupBy
