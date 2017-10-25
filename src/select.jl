import DataFrames.DataFrame
import IndexedTables.IndexedTable

function select(cols)
  return function(df::Union{AbstractDataFrame,IndexedTables})
    column(cols)
  end
end

function select(cols...)
  return function(df::Union{AbstractDataFrame,IndexedTables})
    columns(cols...)
  end
end
