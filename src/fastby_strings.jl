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

function fastby!(fn::Function, x::AbstractVector{String}, z; checksorted = true, checkgrouped = true)
    res = Dict{String, Float64}()

    if checksorted && issorted(x)
        res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, Float64}
    elseif checkgrouped && isgrouped(x)
        res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, Float64}
    else
        y = hash.(x)        
        grouptwo!(y, x);
        if isgrouped(y,x)
            res = FastGroupBy._contiguousby(fn, x, z)::Dict{String, Float64}
        end
    end
    return res
end

# srand(1);
# x = gen_string_vec_id_fixed_len(100_000_000, 10);
# z = ones(length(x));
# @time rh = fastby!(x,z; checksorted = false, checkgrouped = false); # 24 seconds
# @time isgrouped(x)
# @time rh = fastby!(x,z; checksorted = false, checkgrouped = true); # 2.5 seconds
# radixsort_lsd!(x)
# @time rh = fastby!(x, z; checksorted = true, checkgrouped = true); # 2.2 seconds

# srand(1);
# x = gen_string_vec_fixed_len(100_000_000, 10);
# @time rh = hello(x,z); # 26 so added about 2~3 seconds to run time