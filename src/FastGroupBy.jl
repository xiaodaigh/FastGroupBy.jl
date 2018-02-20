__precompile__(true)
module FastGroupBy

##############################################################################
##
## Dependencies
##
##############################################################################
using SortingAlgorithms, Base.Order, Compat, IndexedTables, DataFrames, StatsBase
using SortingLab
using Base.Threads
import Base: ht_keyindex, rehash!, _setindex!, ht_keyindex2, sort!, sortperm, sortperm!, size
import SortingAlgorithms: uint_mapping, RADIX_SIZE, RADIX_MASK
import DataFrames: AbstractDataFrame
import IndexedTables: NDSparse, column
import PooledArrays.PooledArray
import CategoricalArrays.CategoricalArray
import StatsBase: BaseRadixSortSafeTypes, radixsort_safe


##############################################################################
##
## Exported methods and types (in addition to everything reexported above)
##
##############################################################################

export fastby!, column, sumby, sumby!, load_bits, fastby, sort!
export sumby_contiguous, sumby_dict, sumby_radixgroup!, isgrouped
export sumby_radixsort!, sumby_sortperm, sumby
export sumby_multi_rs, sorttwo!, fcollect, grouptwo!, fgroupreduce, fgroupreduce!
export fby, fby!


##############################################################################
##
## Definitions
##
##############################################################################


##############################################################################
##
## Load files
##
##############################################################################
include("sumby.jl")
include("sumby_multithreaded.jl")
include("util.jl")
include("grouptwo.jl")
include("fastby.jl")
include("fastby_strings.jl")
include("fastby_shortstrings.jl")
include("fastby_categoricalarrays_integer.jl")
# include("bits_types.jl")
include("bits_loaders.jl")
include("fgroupreduce.jl")
include("contiguousby.jl")
include("fby_CategoricalVector_multi.jl")

end # module FastGroupBy
