

# only need to be run once to install packages
#Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl.git")
#Pkg.clone("https://github.com/xiaodaigh/FastGroupBy.jl.git")

using Revise, DataBench
using FastGroupBy

const M=100_000_000; const K=100
srand(1)
svec1 = rand(["i"*dec(k,7) for k in 1:M÷K], M)
@time radixsort!(svec1)
issorted(svec1)


using PooledArrays

const N = 100_000_000
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
    l = length(byvec)

    # firstly sort the string by size
    if skip_sizeof_grouping
        ##
    else
        sizevec = sizeof.(svec)
        # typically the range of sizes for
        minsize, maxsize = extrema(svec)
        if  minsize != maxsize
            # if there is only one size then ignore
            indices = collect(1:l)
            # grouptwo!(svec, indices)
        else
        end
    end
end

function isgrouped(x, hashx)
    x1 = x[1]
    hashx1 = hashx[1]
    for i = 2:length(x)
        @inbounds if x1 != x[i]
            if hashx1 == hashx[i]
                return false
            else
                x1 = x[i]
                hashx1 = hashx[i]
            end
        end
    end
    return true
end

function roughhash(s::AbstractString)
    pp = pointer(s)
    sz = sizeof(s)
    hh = zero(UInt64) | Base.pointerref(pp, 1, 1)
    for j = 2:min(sz, 8)
        hh = (hh << 8) | Base.pointerref(pp, j, 1)
    end
    hh
end
@benchmark roughhash(x)

function radixgroup(fn::Function, svec::Vector{T}, valvec::Vector{S}) where {T <: AbstractString, S}
    a = zeros(UInt128, length(svec))
    @time for (i, s) in enumerate(svec)
        pp = pointer(s)
        hh = zero(UInt128) ⊻ Base.pointerref(pp, 1, 1)
        sz = sizeof(s)
        for j = 2:min(16,sz)
            hh = (hh << 8) ⊻ Base.pointerref(pp, j, 1)
            # hh += (hh << 10);
            # hh ^= (hh >> 6);
        end
        @inbounds a[i] = hh
    end
    a
    # @time grouptwo!(a, valvec)
    #
    # res = Dict{T, S}()
    # l = length(svec)
    #
    # j = 1
    # lastby = svec[1]
    # @time for i = 2:l
    #     @inbounds byval = svec[i]
    #     if byval != lastby
    #         viewvalvec = @view valvec[j:i-1]
    #         @inbounds res[lastby] = fn(viewvalvec)
    #         j = i
    #         @inbounds lastby = svec[i]
    #     end
    # end
    #
    # viewvalvec = @view valvec[j:l]
    # @inbounds res[svec[l]] = fn(viewvalvec)
    # return res
end

@time permi = radixgroup(sum, svec, valvec)
using StatsBase
countmap(permi)

hh = zero(UInt)
j=1
pp = pointer(svec[1])
bp = Base.pointerref(pp, j, 1)
hh = xor(hh << 8, bp)
j = j + 1

@code_warntype radixgroup!(svec)

function fastby(fn::Function, byvec::Vector{T}, valvec::Vector) where T <: AbstractString
    permi = radixgroup!(byvec)
    fastby_contiguous(fn, byvec[permi], valvec[permi])
end

function fastby_contiguous(fn::Function, byvec::Vector{T}, valvec::Vector{S}) where {T <: AbstractString, S}
    res = Dict{T, S}()
    l = length(byvec)

    j = 1
    lastby = byvec[1]
    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            viewvalvec = @view valvec[j:i-1]
            @inbounds res[lastby] = fn(viewvalvec)
            j = i
            @inbounds lastby = byvec[i]
        end
    end

    viewvalvec = @view valvec[j:l]
    @inbounds res[byvec[l]] = fn(viewvalvec)
    return res
end

@time fastby(sum, idstr, valvec)

using StatsBase
@time countmap(idstr)
