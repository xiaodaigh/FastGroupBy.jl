using Revise
using DataBench, FastGroupBy

function cmp_3way_lsd(n, strlen)
    srand(1);
    svec = DataBench.gen_string_vec_var_len(n, strlen);
    a = @elapsed three_way_radix_qsort!(svec);
    @assert issorted(svec)

    srand(1);
    svec = DataBench.gen_string_vec_var_len(n, strlen);
    b = @elapsed radixsort_lsd!(svec);
    @assert issorted(svec)

    (a,b)
end


@time cmp_3way_lsd(1_000_000, 8)
@time cmp_3way_lsd(1_000_000, 16)
@time cmp_3way_lsd(1_000_000, 24)
@time cmp_3way_lsd(1_000_000, 32)
@time cmp_3way_lsd(1_000_000, 64)

@time cmp_3way_lsd(10_000_000, 8)
@time cmp_3way_lsd(10_000_000, 16)
@time cmp_3way_lsd(10_000_000, 24)
@time cmp_3way_lsd(10_000_000, 32)
@time cmp_3way_lsd(10_000_000, 64)

@time cmp_3way_lsd(100_000_000, 8)
@time cmp_3way_lsd(100_000_000, 16)
@time cmp_3way_lsd(100_000_000, 24)
@time cmp_3way_lsd(100_000_000, 32)
@time cmp_3way_lsd(100_000_000, 64)