using StatsBase
srand(1)
N = 1_000_000


function findChain{T <: Integer}(a::Vector{T})::Vector{Vector{T}}
  chains = Vector{Vector{T}}([])
  nc = 0

  ac = copy(a)

  while length(ac) > 0
    start_val = ac[1]
    chain = [start_val]

    next_val = a[start_val]
    while next_val != start_val
      push!(chain, next_val)
      next_val = a[next_val]
    end

    nc = nc + 1
    push!(chains, chain)
    ac = setdiff(ac,chain)
  end

  return chains
end

function abc()
  a = sample(Int32(1):Int32(N), N, replace = false)
  res = findChain(a)
  max(length.(res)...) / N
end

[abc() for i in 1:100] |> describe


BitArray(1_000_000_000)
