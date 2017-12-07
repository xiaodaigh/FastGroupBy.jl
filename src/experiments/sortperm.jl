using SortingAlgorithms
import SortingAlgorithms.sortandperm_radix
include("0_setup.jl")

function sumby_sortperm1(by, val)
    (by, p) = sortandperm_radix(by)
    sumby_contiguous(by, val[p])
end

N  = 250_000_000;
K = 100;
by = nothing;
val = nothing;
gc();

# srand(1);
# by = rand(Int32(1):Int32(round(N/K)), N);
# val = rand(Int32(1):Int32(5), N)
# @time res1 = sumby_sortperm1(by, val)

srand(1);
by = rand(Int32(1):Int32(round(N/K)), N);
val = rand(Int32(1):Int32(5), N);
@time res2 = sumby(by, val);

function sumby_sortperm2(by, val)
    (by, p) = sortandperm_radix(by)
    sumby_contiguous(by, @view val[p])
end

srand(1);
by = rand(Int32(1):Int32(round(N/K)), N);
val = rand(Int32(1):Int32(5), N);
@time res3 = sumby_sortperm2(by, val)

srand(1);
by = rand(Int32(1):Int32(round(N/K)), N);
val = rand(Int32(1):Int32(5), N);
@time res4 = sumby_radixsort(by, val)

res2 == res3
res3 == res4
