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

"https://discourse.julialang.org/t/whats-the-fastest-way-to-generate-1-2-n/7564/15"
using Base.Threads
function fcollect(N,T=Int)
    nt = nthreads()
    n,r = divrem(N,nt)
    a = Vector{T}(N)
    @threads for i=1:nt
        ioff = (i-1)*n
        nn = ifelse(i == nt, n+r, n)
        @inbounds for j=1:nn
            a[ioff+j] = ioff+j
        end
    end
    a
end
