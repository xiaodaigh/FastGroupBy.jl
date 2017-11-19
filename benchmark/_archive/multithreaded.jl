include("./0_setup.jl")

N = 250_000_000
K = 100

# srand(1);
# id6 = rand(Int32(1):Int32(round(N/K)), N);
# v1 =  rand(Int32(1):Int32(5), N);
# @elapsed sumby_multi_rg(id6, v1)



function bench_sumby_multi_van()
    srand(1);
    id6 = rand(Int32(1):Int32(round(N/K)), N);
    v1 =  rand(Int32(1):Int32(5), N);
    @elapsed sumby_multi_van(id6, v1)
end

function bench_sumby()
    srand(1)
    id6 = rand(Int32(1):Int32(round(N/K)), N)
    v1 =  rand(Int32(1):Int32(5), N)
    @elapsed sumby(id6, v1)
end

function bench_sumby_radixgroup()
    srand(1)
    id6 = rand(Int32(1):Int32(round(N/K)), N)
    v1 =  rand(Int32(1):Int32(5), N)
    @elapsed sumby_radixgroup(id6, v1)
end

function bench_sumby_radixsort()
    srand(1)
    id6 = rand(Int32(1):Int32(round(N/K)), N)
    v1 =  rand(Int32(1):Int32(5), N)
    @elapsed sumby_radixsort(id6,v1)
end

a  = [bench_sumby_multi_rs() for i=1:5]
b = [bench_sumby_radixgroup() for i=1:5]

1-mean(a)/mean(b)
mean(a)
mean(b)

srand(1)
id6 = rand(Int32(1):Int32(round(N/K)), N)
v1 =  rand(Int32(1):Int32(5), N)
@time res = sumby_multi_rs(by, v1)



#[bench_sumby_multi_van() for i=1:5]
#[bench_sumby() for i=1:5]
#[bench_sumby_radixsort() for i=1:5]
