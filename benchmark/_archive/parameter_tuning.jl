include("../src/experiments/0_setup.jl")
import DataFrames.DataFrame
using DataFrames, CSV
using FastGroupBy
using Base.Threads
K = 100


tries = vcat([Int(2^k-1) for k = 7:31], 3_000_000_000)
for N in tries
    println(N)
    if N < 2_000_000
        by = nothing; val = nothing; gc()
        srand(1)
        by = rand(Int64(1):Int64(round(N/K)), N);
        val = rand(Int32(1):Int32(5), N);
        sp  = @elapsed sumby_sortperm(by, val)
        CSV.write(string("benchmark/out/64/sp$N $(replace(string(now()),":","")).csv"),DataFrame(sp = sp))
    end

    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int64(1):Int64(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    srs = @elapsed sumby_multi_rs(by, val)
    CSV.write(string("benchmark/out/64/mrs$N $(replace(string(now()),":","")).csv"),DataFrame(srs = srs))

    if N < 2_000_000_000
        by = nothing; val = nothing; gc()
        srand(1)
        by = rand(Int64(1):Int64(round(N/K)), N);
        val = rand(Int32(1):Int32(5), N);
        srg = @elapsed sumby_radixgroup(by, val)
        CSV.write(string("benchmark/out/64/srg$N $(replace(string(now()),":","")).csv"),DataFrame(srg = srg))
    end

    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int64(1):Int64(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    srs = @elapsed sumby_radixsort(by, val)
    CSV.write(string("benchmark/out/64/srs$N $(replace(string(now()),":","")).csv"),DataFrame(srs = srs))
end


tries = vcat([Int(2^k-1) for k = 7:31], 3_000_000_000)
for N in tries
    println(N)
    if N < 400_000
        by = nothing; val = nothing; gc()
        srand(1)
        by = rand(Int32(1):Int32(round(N/K)), N);
        val = rand(Int32(1):Int32(5), N);
        sp  = @elapsed sumby_sortperm(by, val)
        CSV.write(string("benchmark/out/sp$N $(replace(string(now()),":","")).csv"),DataFrame(sp = sp))
    end

    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int32(1):Int32(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    srs = @elapsed sumby_multi_rs(by, val)
    CSV.write(string("benchmark/out/mrs$N $(replace(string(now()),":","")).csv"),DataFrame(srs = srs))

    if N < 2_000_000_000
        by = nothing; val = nothing; gc()
        srand(1)
        by = rand(Int32(1):Int32(round(N/K)), N);
        val = rand(Int32(1):Int32(5), N);
        srg = @elapsed sumby_radixgroup(by, val)
        CSV.write(string("benchmark/out/srg$N $(replace(string(now()),":","")).csv"),DataFrame(srg = srg))
    end

    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int32(1):Int32(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    srs = @elapsed sumby_radixsort(by, val)
    CSV.write(string("benchmark/out/srs$N $(replace(string(now()),":","")).csv"),DataFrame(srs = srs))
end
