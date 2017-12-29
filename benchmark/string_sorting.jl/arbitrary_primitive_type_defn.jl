using FastGroupBy,InternedStrings
import FastGroupBy.mask16bit
const N = 100_000_000; const K = 100
srand(1);
@time sample_space = [string(rand(Char.(97:97+25), rand(1:16))...) for k in 1:N÷K];
@time svec = rand(sample_space, N);
@time radixsort!(UInt192,svec)
issorted(svec)

T = UInt192
i = 1
@time vs = FastGroupBy.load_bits.(T, svec, Int(i-1)*sizeof(T));
@time FastGroupBy.sorttwo_lsd16!(vs1, svec);

srand(1);
@time sample_space = [string(rand(Char.(97:97+25), rand(1:24))...) for k in 1:N÷K];
@time svec = rand(sample_space, N);
@time vs1 = FastGroupBy.load_bits_fast.(T, svec);
@time FastGroupBy.sorttwo_lsd!(vs1, svec)

using BenchmarkTools
T = UInt128
i = 1
srand(1);
@time sample_space = [string(rand(Char.(97:97+25), rand(1:16))...) for k in 1:N÷K];
@time svec = rand(sample_space, N);
function fn1(svec, T) 
    @time vs1 = FastGroupBy.load_bits_fast.(T, svec); # 11
    @time FastGroupBy.sorttwo_lsd16!(vs1, svec); # 21
end;
@time fn1(svec, T); #34 #37
issorted(svec)

srand(1);
@time sample_space = [string(rand(Char.(97:97+25), rand(1:16))...) for k in 1:N÷K];
@time svec = rand(sample_space, N);
function fn2(svec, T)    
    @time vs1 = FastGroupBy.load_bits_fast.(T, svec); # 11
    @time FastGroupBy.sorttwo_lsd!(vs1, svec); # 21
end
@time fn2(svec, T);
issorted(svec, T) #31 #44

srand(1);
@time sample_space = [string(rand(Char.(97:97+25), rand(1:16))...) for k in 1:N÷K];
@time svec = rand(sample_space, N);
function fn3(svec, T)
    @time vs1 = FastGroupBy.load_bits_fast.(T, svec); # 11
    @time FastGroupBy.sorttwo!(ntoh.(vs1), svec); #29
end
@time fn3(svec, T); #40 #30
issorted(svec)

srand(1);
@time sample_space = [string(rand(Char.(97:97+25), rand(1:16))...) for k in 1:N÷K];
@time svec = rand(sample_space, N);
function fn4(svec, T)    
    @time vs1 = FastGroupBy.load_bits_fast_ntoh.(T, svec); #2
    @time FastGroupBy.sorttwo!(vs1, svec) #18
end
@time fn4(svec, T); #47 #40
issorted(svec)



@time sorttwo!(vs, svec)
@time issorted(svec)

@time radixsort!(UInt192,svec)
issorted(svec)


T = UInt
i = 1
@time vs = FastGroupBy.load_bits.(T, svec, Int(i-1)*sizeof(T));
@time vs1 = load_bits.(T, svec, Int(i-1)*sizeof(T));




@time radixsort!(UInt128,svec)
issorted(svec)
index = svec;