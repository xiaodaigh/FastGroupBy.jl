__precompile__(true)
module FastGroupBy

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
export sumby_htsize, sumby_sorted, sumby_dict

##############################################################################
##
## Load files
##
##############################################################################

include("meanby.jl")
include("sumby.jl")
include("util.jl")
include("pgroupreduce.jl")

end # module FastGroupBy
