# only need to be run once to install packages
#Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git")
#Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")

using FastGroupBy, PooledArrays

const N = 1_000_000
# const N = Int(2^31-1) # 368 seconds to run
const K = 100

using Base.Threads
nthreads()

srand(1)
# generate string ids
function randstrarray1(pool, N)
    K = length(pool)
    PooledArray(PooledArrays.RefArray(rand(1:K, N)), pool)
end
const pool1 = [@sprintf "id%010d" k for k in 1:(N/K)]
const id3 = randstrarray1(pool1, N)
v1 =  rand(Int32(1):Int32(5), N)

# treat it as Pooledarray
@time sumby(id3, v1)
@time fastby(id3, v1, sum)

# treat by as strings and use dictionary method; REALLY SLOW
const id3_str = rand(pool1, N)
@time sumby(id3_str, v1)

@time Int.(getindex.(id3_str,1 ))

@time all(isascii.(id3_str))

@time sort(id3_str)

srand(1)
pool_str = rand([@sprintf "id%010d" k for k in 1:(N/K)], N)
id = rand(1:K, N)
valvec = rand(N)
@time all(isascii.(pool_str))
@time svec = sizeof.(pool_str)
by_vec = pool_str

using FastGroupBy
@time sumby_dict(zip(pool_str, id), valvec)

# fast group by for unicode strings
function fastby!(fn::Function, byvec::Vector{T}, valvec::Vector{S}, skip_sizeof_grouping = false, ascii_only = false) where {T<:AbstractString,S}
    if ascii_only || all(isascii.(byvec))
        return Dict{T, S}{}
    end
    l = length(byvec)

    # firstly sort the string by size
    if skip_sizeof_grouping
        ##
    else
        svec = sizeof.(svec)
        # typically the range of sizes for
        minsize, maxsize = extrema(svec)
        if  minsize != maxsize
            # if there is only one size then ignore
            indices = collect(1:l)
            grouptwo!(svec, indices)
        else
    end
end

# sorting in data.frame is slow
if false
    using DataFrames
    srand(1)
    @time df = DataFrame(idstr = rand([@sprintf "id%03d" k for k in 1:(N/K)], N)
        , id = rand(1:K, N)
        , val = rand(N))

    @time sort!(df,cols=[:id, :val])
end

function fastby!(fn:: Function, byitr, valvec::AbstractVector{S})
    # use dictionary for iterables
    i  = start(byitr)
    val,  i = next(byitr, i)
    res = Dict{eltype(val), S}
end
