
N  = 100_000_000
K = 100
by = nothing; val = nothing; gc()
srand(1)
by = rand(Int32(1):Int32(round(N/K)), N);
val = rand(Int32(1):Int32(5), N);
@time sumby_nosort(by, val)

by = nothing; val = nothing; gc()
srand(1)
by = rand(Int32(1):Int32(round(N/K)), N);
val = rand(Int32(1):Int32(5), N)
@time sumby(by, val)

N  = 3_000_000_000
K = 100
by = nothing; val = nothing; gc()
srand(1)
by = rand(Int32(1):Int32(round(N/K)), N);
val = rand(Int32(1):Int32(5), N);
@time res = sumby_nosort(by, val)

by = nothing; val = nothing; gc()
srand(1)
by = rand(Int32(1):Int32(round(N/K)), N);
val = rand(Int32(1):Int32(5), N)
@time sumby(by, val)
