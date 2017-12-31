__precompile__(true)
module FastGroupBy

##############################################################################
##
## Dependencies
##
##############################################################################
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
## Exported methods and types (in addition to everything reexported above)
##
##############################################################################

export fastby!, column, sumby, sumby!, load_bits, fastby
export sumby_contiguous, sumby_dict, sumby_radixgroup!
export sumby_radixsort!, sumby_sortperm, sumby
export sumby_multi_rs, fsortandperm_radix!,sorttwo!,fcollect, grouptwo!
export radixsort_lsd!, Bits24, Bits192, str_qsort!, three_way_radix_qsort!

##############################################################################
##
## Definitions
##
##############################################################################
const BaseRadixSortSafeTypes = Union{Int8, Int16, Int32, Int64, Int128,
                                     UInt8, UInt16, UInt32, UInt64, UInt128}
                                     
radixsort_safe(::Type{T}) where {T<:BaseRadixSortSafeTypes} = true
radixsort_safe(::Type) = false

##############################################################################
##
## Load files
##
##############################################################################
include("sumby.jl")
include("sortandperm.jl")
include("sumby_multithreaded.jl")
include("util.jl")
include("grouptwo.jl")
include("string_sort/string_radixsort.jl")
include("fastby.jl")
include("bits_types.jl")
include("string_sort/ccmp_sort.jl")
include("string_sort/three_way_radix_quicksort.jl")

end # module FastGroupBy
