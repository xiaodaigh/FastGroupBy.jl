using BenhmarkTools
x = "id".*dec.(1:1_000_000, 10);
rx = rand(x, 100_000_000);

function fhash(z)
    pz = z |> pointer |> Ptr{UInt}
    h = pz |> unsafe_load |> hash
    h1 = (pz + 8) |> unsafe_load |> hash
    h * h1
end

@benchmark hash.($rx)
# BenchmarkTools.Trial:
#   memory estimate:  762.94 MiB
#   allocs estimate:  2
#   --------------
#   minimum time:     16.816 s (0.00% GC)
#   median time:      16.816 s (0.00% GC)
#   mean time:        16.816 s (0.00% GC)
#   maximum time:     16.816 s (0.00% GC)
#   --------------
#   samples:          1
#   evals/sample:     1
@benchmark fhash.($rx) # 8

@benchmark Base.crc32c.($rx)

a = (z->z |> pointer |> Ptr{UInt} |> unsafe_load).(rx) 


fshash(z) = z |> pointer |> Ptr{UInt} |> unsafe_load |> hash
fshash1(z) = z |> pointer |> Ptr{UInt} |> unsafe_load

@benchmark fshash.($rx)
@benchmark fshash1.($rx)
@benchmark hash.($a)


@benchmark sort.(a)

@time aa = fshash1.(rx)
@benchmark sort($aa)
@benchmark sort($aa, alg=RadixSort)