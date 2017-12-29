using FastGroupBy,InternedStrings
import FastGroupBy.mask16bit
const N = 100_000_000; const K = 100
srand(1);
@time sample_space = [string(rand(Char.(97:97+25), rand(1:24))...) for k in 1:N÷K];
@time svec = rand(sample_space, N);
@time radixsort!(UInt192,svec)
issorted(svec)

T = UInt192
i = 1
@time vs = FastGroupBy.load_bits.(T, svec, Int(i-1)*sizeof(T));
index = svec;



unsafe_load(Ptr{UInt256}(svec[1].value))

primitive type  UInt256 256 end

using FastGroupBy
x = unsafe_load(Ptr{UInt24}(pointer("abc")))
y = unsafe_load(Ptr{UInt24}(pointer("def")))

Base.unsafe_convert(UInt24, 0xffffff)

z = UInt(16^5*15 + 16^4*15 + 16^3*15 + 16^2*15 + 16*15+ 15)
unsafe_load(Ptr{UInt24}(pointer_from_objref(z)))

Base.and_int(x,y)
x & y

promote_rule(::Type{UInt24}, ::Union{Type{Int16}, Type{Int8}, Type{UInt16}, Type{UInt8}}) = UInt32

UInt(x)

unsafe_load(Ptr{UInt16}(pointer(string("a", Char(8*16+15)))))

unsafe_load(pointer(string(Char(255))))

@which convert(UInt, UInt16(15))


promote(x, 65) & 0xff

# bitshifts work fine
x 
x >> 8
x << 8

Base.and_int(65, 0xff)

@which x & 0xff

typeof(65) <: Base.BitInteger
typeof(0xff) <: Base.BitInteger