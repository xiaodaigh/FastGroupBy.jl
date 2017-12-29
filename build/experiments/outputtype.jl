using StatsBase
function apply_fn2a(fn::Array{Function}, a)
    x, y = (fn1(a) for fn1 in fn)
    (x,y)
end


srand(1)
const xx = rand(1:100, 100_000_000)

@time a = apply_fn2a([countmap,sum], xx)
@code_warntype apply_fn2a([countmap,sum], xx)

function apply_fn2a(fn::Vector{Function}, a, outputType::Type)::outputType
    res = Tuple(fn1(a) for (i,fn1) in enumerate(fn))::outputType
    res
end

using BenchmarkTools
@benchmark a_without_out_type = apply_fn2a(
    [mean,sum]
    , xx)

@benchmark a_with_out_type = apply_fn2a(
    [mean,sum],
    xx,
    Tuple{Float64,Int64})

@code_warntype apply_fn2a([mean,sum], xx, Tuple{Dict{Int64, Int64},Int64})

sqrt(-1)

import Base.sqrt
sqrt(x, ::Type{Complex}) = sqrt(Complex(x))
sqrt(-1, Complex)

function apply_fn2a(fn::Function, a)
    fn(a)
end

@code_warntype apply_fn2a(sum, rand(1000))


function apply_fn2a(fn::Function, a::Vector)
    fn(a)
end

@code_warntype apply_fn2a(sum, rand(1000))

@code_warntype apply_fn2a(rand(1000)) do x
    x[end] - x[1]
end

const a = rand(1:5, 100)
using StatsBase
@code_warntype apply_fn2a.([countmap, mean], a)

apply_fn2a.([countmap, mean], a)



const a = rand(1:5, 100)
using StatsBase
function apply_fn2a(fn::Tuple{Function, Function},a)
    (fn[1](a), fn[2](a))
end

apply_fn2a((countmap, sum), a)

@code_warntype apply_fn2a((countmap, sum), a)

function apply_fn2a(fn::Tuple,a)
    Tuple(fn[1](a), fn[2](a))
end
@code_warntype apply_fn2a([countmap, sum], a)

function apply_fn2a(fn::Tuple{Function, Function},a)
    (fn[1](a), fn[2](a))
end

const x = rand(1:5, 100)
using StatsBase
@code_warntype apply_fn2a((countmap, sum), x)

function apply_fn2a(fns::Tuple,a)
    Tuple(fn(a) for fn in fns)
end

using StatsBase
const x = rand(1:5,1000)
@code_warntype apply_fn2a((countmap, sum, mean), x)
