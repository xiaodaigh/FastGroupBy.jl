using BenchmarkTools

C_code = raw"""
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int compare(const void* l, const void* r){
    char* cl = *(char**)l+8;
    char* cr = *(char**)r+8;
    return strcmp(cl, cr);
}

void str_qsort(char **strings, size_t len) {  /* you need to pass len here */
    
    /* qsort(strings, len, sizeof(char*), (int (*)(void*, void*))strcmp); */
    qsort(strings, len, sizeof(char*), compare);
    
}   
"""

const Clib = "strqsort" # tempname()   # make a temporary file


# compile to a shared library by piping C_code to gcc
# (works only if you have gcc installed):

open(`gcc -fPIC -O3 -msse3 -xc -shared -o $(Clib * "." * Libdl.dlext) -`, "w") do f
    print(f, C_code) 
end


# define a Julia function that calls the C function:
str_qsort(X::Array{String}) = ccall(("str_qsort", Clib), Void, (Ptr{UInt64}, Cint), reinterpret(Ptr{UInt64}, pointer(X)), length(X))

a = [String([Char(i)]) for i in 'Z':-1:'A']
println("before sort: $a")
@btime str_qsort($a)
println("after sort: $a")

const M=100_000_000; const K=100
srand(1)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
l = length(svec1)
println("before sort: length=$l")
# for i in 1:length(svec1)-1 
#    if svec1[i]>svec1[i+1]
#       println("it is ok now to have unordered strings! svec1[$i]>svec1[$(i+1)] \"$(svec1[i])\">\"$(svec1[i+1])\"")
#       break
#    end
# end

@time str_qsort(svec1)
issorted(svec1)
# l = length(svec1)
# println("after sort length=$l")
# global sorted = true
# for i in 1:length(svec1)-1 
#    if svec1[i]>svec1[i+1]
#       println("error svec1[$i]>svec1[$(i+1)] $(svec1[i])>$(svec1[i+1])")
#       sorted = false
#       break
#    end
# end
# println(sorted ? "sorted! :)" : "unsorted! :(")

const M=100_000_000; const K=100
using FastGroupBy
srand(1)
svec1 = rand([string(rand(Char.(32:126), rand(1:8))...) for k in 1:M÷K], M)
@time FastGroupBy.radixsort!(svec1) # 29 seconds
issorted(svec1)


