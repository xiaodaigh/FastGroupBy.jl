import DataFrames.AbstractDataFrame
import DataFrames.DataFrame
import IndexedTables.IndexedTable

"""
  column(df, :colname)

Extract a column from an AbstractDataFrame
"""
function column(dt::AbstractDataFrame, col::Symbol)
  i = dt.colindex.lookup[col]
  dt.columns[i]
end

"""
  select(:col)

Return a funciton that obtains a column with the named symbol from an AbstractDataFrame or IndexedTable
"""
function select(col::Symbol)
  return function(df::Union{AbstractDataFrame,IndexedTable})
    column(df, col)
  end
end
