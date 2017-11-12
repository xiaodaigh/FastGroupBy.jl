
N  = Int(80960/2)
K = 100
a = 0
b = 1
lo = 0
hi = 1024000

while true
    println(N)
    by = nothing; val = nothing; gc()
    srand(1)
    by = rand(Int32(1):Int32(round(N/K)), N);
    val = rand(Int32(1):Int32(5), N);
    a = @belapsed sumby_sortperm(by, val)
    b = @belapsed sumby(by, val)
    println(string(a,":",b))

    if a < b # if sortperm was faster
        lo = N
        N = Int((hi + lo)/2)
    else a >= b # if sumby is faster
        if hi - lo <= 4096; break;end;
        hi = N
        N = Int((hi + lo)/2)
    end
end
println(string("done:", N))
