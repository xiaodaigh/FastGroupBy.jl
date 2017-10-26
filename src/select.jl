import DataFrames.DataFrame
import IndexedTables.IndexedTable

function select(cols::Symbol)
  return function(df::Union{AbstractDataFrame,IndexedTable})
    column(df, cols)
  end
end
