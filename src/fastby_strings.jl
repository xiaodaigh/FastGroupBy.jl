# function gen_string_vec_fixed_len(n, strlen, grps = max(n ÷ 100,1), range = vcat(48:57,65:90,97:122))
#     rand([string(rand(Char.(range), strlen)...) for k in 1:grps], n)
# end

# function gen_string_vec_id_fixed_len(n, strlen = 10, grps = max(n ÷ 100,1), prefix = "id")
#     rand([prefix*dec(k,strlen) for k in 1:grps], n)
# end

# using FastGroupBy, SortingAlgorithms
function isgrouped(testgrp, truegrp)
    # find where the change happens
    res = true
    for i = 2:length(testgrp)
        if testgrp[i] != testgrp[i-1]
            if truegrp[i] == truegrp[i-1]
                #println(i)
                res = false
                break
            end
        end
    end
    res
end

function fastby2!(fn::Function, x::AbstractVector{String}, z::AbstractVector{S}, outType = typeof(fn(z[1:1])); checksorted = true, checkgrouped = true) where S    
    res = Dict{String, outType}()
    if checksorted && issorted(x)
        res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, outType}
    elseif checkgrouped && isgrouped(x)
        res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, outType}
    else
        y = hash.(x)
        #xz is the x and the z
        xz  = FastGroupBy.ValIndexVector(x, z)
        grouptwo!(y, xz);
        if isgrouped(y, xz)
            res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, outType}
        end
    end
    return res
end

function fastby!(fn::Function, x::AbstractVector{String}, z::AbstractVector{S}, outType = typeof(fn(z[1:1])); checksorted = true, checkgrouped = true) where S    
    res = Dict{String, outType}()
    if checksorted && issorted(x)
        res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, outType}
    elseif checkgrouped && isgrouped(x)
        res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, outType}
    else
        idx = fsortperm(x);
        res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, outType}
    end
    return res
end

fastby(fn::Function, x::AbstractVector{String}, z::AbstractVector{S}, outType = typeof(fn(z[1:1])); checksorted = true, checkgrouped = true) where S = fastby!(fn, copy(x), coopy(z), outType, checkedsorted = checkedsorted, checkgrouped = checkgrouped)

if false
    using DataBench, FastGroupBy, SortingLab, SortingAlgorithms
    srand(1);
    # x = gen_string_vec_id_fixed_len(100_000_000, 10);
    ss = "id".*dec.(1:100,3)
    x = rand(ss, 10_000_000)
    z = rand(length(x));
    
    @time radixsort(x);
    @time hx = hash.(x);
    @time sort(hx, alg=RadixSort);
    @time rh = fastby2!(sum, x,z; checksorted = false, checkgrouped = false); # 3.45s string; 24 seconds
    @time isgrouped(x)
    @time rh = fastby!(x,z; checksorted = false, checkgrouped = true); # 2.5 seconds
    radixsort_lsd!(x)
    @time rh = fastby!(x, z; checksorted = true, checkgrouped = true); # 2.2 seconds
end

# srand(1);
# x = gen_string_vec_fixed_len(100_000_000, 10);
# @time rh = hello(x,z); # 26 so added about 2~3 seconds to run time