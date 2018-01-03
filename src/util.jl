using Base.Threads
import DataFrames.AbstractDataFrame
import DataFrames.DataFrame
import IndexedTables.NDSparse

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

Return a funciton that obtains a column with the named symbol from an AbstractDataFrame or NDSparse
"""
function select(col::Symbol)
  return function(df::Union{AbstractDataFrame,NDSparse})
    column(df, col)
  end
end

# from https://discourse.julialang.org/t/whats-the-fastest-way-to-generate-1-2-n/7564/15?u=xiaodai
using Base.Threads
function fcollect(N::Integer, T = Int)
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

# a general isgrouped algorithm
function isgrouped(grps::AbstractVector)
  # find where the change happens
  a = BitArray(2^(sizeof(UInt32)*8))

  hindex = hash(grps[1])

  a[Base.trunc_int(UInt32,hindex) + 1] = true
  a[Base.trunc_int(UInt32,hindex >> 32) + 1] = true

  for i = 2:length(grps)
      if grps[i-1] != grps[i]            
          hindex = hash(grps[i])
          hindex1 = Base.trunc_int(UInt32, hindex) + 1
          hindex2 = Base.trunc_int(UInt32, hindex >> 32) + 1            
          if a[hindex1] && a[hindex2]                
              return false
          else 
              a[hindex1] = true
              a[hindex2] = true
          end
      end
  end
  return true
end