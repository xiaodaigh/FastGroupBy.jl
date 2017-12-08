using FastGroupBy
using Base.Test

a = [1, 1, 2, 3, 3];
aa = sumby(a,a);
@test length(aa) == 3
b = Dict(1=>2, 2=>2, 3 => 6)
@test aa == b
