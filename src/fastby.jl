function fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T, S}
    length(byvec) == length(valvec) || throw(DimensionMismatch())
    isbits(T) || throw(ErrorException("vector type is not bits"))
    _fastby!(fn, byvec, valvec)
end

# hello
function _fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T, S}
    _fastby!(byvec, valvec, [fn], [outputType])
    # l = length(byvec)
    # grouptwo!(byvec, valvec)
    # lastby = byvec[1]
    #
    # res = Dict{T,outputType}()
    #
    # j = 1
    #
    # for i = 2:l
    #     @inbounds byval = byvec[i]
    #     if byval != lastby
    #         @inbounds res[lastby] = fn(@view(valvec[j:i-1]))::outputType
    #         j = i
    #         @inbounds lastby = byvec[i]
    #     end
    # end
    #
    # @inbounds res[byvec[l]] = fn(@view valvec[j:l])::outputType
    # return res
end

function _fastby!(fn::Vector{Function}, byvec::AbstractVector{T}, valvec::AbstractVector{S}, outputType::Vector{DataType} = [S for i = 1:length(fn)]) where {T, S}
    l = length(byvec)
    grouptwo!(byvec, valvec)
    lastby = byvec[1]

    res = Dict{T,Tuple{outputType...}}()

    j = 1

    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            viewvalvec = @view valvec[j:i-1]
            @inbounds res[lastby] = ((fn1(viewvalvec) for fn1 in fn)...)
            j = i
            @inbounds lastby = byvec[i]
        end
    end

    viewvalvec = @view valvec[j:l]
    @inbounds res[byvec[l]] = ((fn1(viewvalvec) for fn1 in fn)...)
    return res
end

srand(1)
x = rand(1:1_000_000, 100_000_000)
y = rand(100_000_000)
@time a = _fastby!(x,y, sum)
srand(1)
x = rand(1:1_000_000, 100_000_000)
y = rand(100_000_000)
@time a = _fastby!(x,y, sum)

srand(1)
x = rand(1:1_000_000, 100_000_000)
y = rand(100_000_000)
@time a = fastby!(x,y, sum)
srand(1)
x = rand(1:1_000_000, 100_000_000)
y = rand(100_000_000)
@time a = fastby!(x,y, sum)

srand(1)
x = rand(1:1_000_000, 100_000_000)
y = rand(100_000_000)
@time a = sumby_radixsort(x,y)

function fastby(byvec::AbstractVector{T}, valvec::AbstractVector{S}, fn::Vector{Function}) where {T, S}
end

x,y = rand(1:5,100), rand(100)
a = fastby!(copy(x),copy(y), sum)
b = sumby(copy(x),copy(y))

[abs(a[k1]-b[k1]) < 0.00000000001 for k1 in keys(a)] |> all

using BenchmarkTools

function abc()
    x = rand(1:1_000_000, 100_000_000)
    y = rand(100_000_000)
    @elapsed a = fastby!(x,y, sum)
end

function abc1()
    x = rand(1:1_000_000, 100_000_000)
    y = rand(100_000_000)
    @elapsed a = fastby!(x,y, sum, Float64)
end

function def()
    x = rand(1:1_000_000, 100_000_000)
    y = rand(100_000_000)
    @elapsed b = sumby_radixsort(x,y)
end

srand(1)
aa = [abc() for i = 1:5]

srand(1)
bb = [def() for i =1:5]

srand(1)
c = [abc1() for i =1:5]

aa |> mean
bb |> mean
c |> mean

srand(1)
x = rand(1:1_000_000, 100_000_000)
y = rand(100_000_000)
@time a = _fastby!(x,y, sum)

srand(1)
x = rand(1:1_000_000, 100_000_000)
y = rand(100_000_000)
@time b = sumby_radixsort(x,y)

@code_warntype fastby!(x,y, sum)

@code_warntype _fastby!(x,y, sum, Float64)

srand(1)
function hihi()
    x = rand(1:1_000_000, 100_000_000)
    y = rand(100_000_000)
    @elapsed a = _fastby!(x,y, [sum, mean])
end

srand(1)
hi = [hihi() for i =1:5]
mean(hi)
