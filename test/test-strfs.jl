using StrFs, BenchmarkTools

primitive type String6 <: AbstractString 48 end
primitive type Bits48 48 end
primitive type Bits64 64 end
primitive type Bits32 32 end
primitive type Bits96 96 end

String(s::String6) = begin
    String(reinterpret(UInt8, [s]))
end

import Base:iterate
iterate(s::String6) = iterate(String(s))
iterate(s::String6, i) = iterate(String(s), i)

gender = [strf"abc", strf"female", strf"abcdefgh"]



#@time ass = ShortString7.(a);

#iterate(s::StrF, i::Integer) = iterate(String(s), i)
#iterate(s::StrF) = iterate(String(s))


using CSV
df = DataFrame(
    a=a,
    as = as
    );

@time CSV.write("c:/data/a.csv", df);


# Base.summarysize(a)
# Base.summarysize(as)

using BenchmarkTools, SortingLab, SortingAlgorithms

@time sort!(as, alg = RadixSort)

@elapsed a_sorted = SortingLab.fsort(a)
@elapsed as_sorted = sort(as, alg=RadixSort)
@elapsed ass_sorted = ShortStrings.fsort(ass)


using Blosc

@time ass_compressed = Blosc.compress(ass)

@time Base.summarysize(ass_compressed)

Ptr{UInt}(Ref(gender[1]))


unsafe_pointer_to_objref(gender[1])



Ptr{StrF{8}}

ss = gender[1]

reinterpret(UInt, UInt8.(ss.bytes))


using Blosc

compress(gender)

uint_mapping(_, s::StrF{S}) where S = begin
    Int(ceil(S/8))*8
end

uint_mapping(1, gender[1])

using SortingAlgorithms
sort(gender, alg = RadixSort)


reinterpret(String6, gender)

ptrs = Vector{UInt8}(undef, 8) |> pointer
x = unsafe_load(Ptr{Bits96}(ptrs))

reinterpret(UInt8, [x])

x = "abc"
using BenchmarkTools
@btime Base.zext_int(UInt64, unsafe_load(Ptr{Bits48}(pointer(x))))


UInt8.(Vector{Char}(x)


reinterpret(String6, UInt8[2, 3, 4, 6, 8, 9])


iterate(s::String6) = s |

Vector{String6}(undef, 222)

unsafe_load(Ptr{String6})
