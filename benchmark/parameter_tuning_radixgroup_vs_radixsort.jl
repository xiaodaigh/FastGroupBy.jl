include("../src/experiments/0_setup.jl")
import DataFrames.DataFrame
using DataFrames, CSV

K = 100

tries = vcat([Int(2^k-1) for k = 7:31], 3_000_000_000)

for N in tries
    println(N)
    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int32(1):Int32(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    sp  = @belapsed sumby_sortperm(by, val)
    CSV.write(string("benchmark/out/sp$N $(replace(string(now()),":","")).csv"),DataFrame(sp = sp))

    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int32(1):Int32(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    srg = @belapsed sumby_radixgroup(by, val)
    CSV.write(string("benchmark/out/srg$N $(replace(string(now()),":","")).csv"),DataFrame(srg = srg))

    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int32(1):Int32(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    srs = @belapsed sumby_radixsort(by, val)
    CSV.write(string("benchmark/out/srs$N $(replace(string(now()),":","")).csv"),DataFrame(srs = srs))
end

for N in tries
    println(N)
    if N < 1_000_000
        by = nothing; val = nothing; gc()
        srand(1)
        by = rand(Int64(1):Int64(round(N/K)), N);
        val = rand(Int32(1):Int32(5), N);
        sp  = @belapsed sumby_sortperm(by, val)
        CSV.write(string("benchmark/out/64/sp$N $(replace(string(now()),":","")).csv"),DataFrame(sp = sp))
    end

    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int64(1):Int64(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    srg = @belapsed sumby_radixgroup(by, val)
    CSV.write(string("benchmark/out/64/srg$N $(replace(string(now()),":","")).csv"),DataFrame(srg = srg))

    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int64(1):Int64(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    srs = @belapsed sumby_radixsort(by, val)
    CSV.write(string("benchmark/out/64/srs$N $(replace(string(now()),":","")).csv"),DataFrame(srs = srs))
end
