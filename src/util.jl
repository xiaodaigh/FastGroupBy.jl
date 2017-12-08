import DataFrames.AbstractDataFrame

"""
  column(df, :colname)

Extract a column from an AbstractDataFrame
"""
function column(dt::AbstractDataFrame, col::Symbol)
  i = dt.colindex.lookup[col]
  dt.columns[i]
end

# """
#   select(:col)
#
# Return a funciton that obtains a column with the named symbol from an AbstractDataFrame or NDSparse
# """
# function select(col::Symbol)
#   return function(df::Union{AbstractDataFrame,NDSparse})
#     column(df, col)
#   end
# end
