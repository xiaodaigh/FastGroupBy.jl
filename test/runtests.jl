using FastGroupBy
using Base.Test

# dt = createIndexedTable(1_000_000, 100);
# @test length(sumby(dt, :id1, :v1)) == 100
@test 1==1

a = [1, 1, 2, 3, 3];
aa = sumby(a,a);
@test length(aa) == 3
b = Dict(1=>2, 2=>2, 3 => 6)
@test all([aa[k]/b[k] for k in keys(aa)] .== 1)
