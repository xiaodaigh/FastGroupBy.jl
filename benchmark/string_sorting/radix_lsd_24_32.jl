using FastGroupBy, DataBench
svec = DataBench.gen_string_vec_var_len(1_000_000, 24);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd16!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(1_000_000, 24);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd24!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(10_000_000, 24);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd16!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(10_000_000, 24);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd24!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(100_000_000, 24);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd16!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(100_000_000, 24);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd24!(svec)
@assert issorted(svec)


svec = DataBench.gen_string_vec_var_len(1_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd16!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(1_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd24!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(1_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd32!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(10_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd16!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(10_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd24!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(10_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd32!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(100_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd16!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(100_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd24!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(100_000_000, 32);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd32!(svec)
@assert issorted(svec)


svec = DataBench.gen_string_vec_var_len(10_000_000, 64);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd16!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(10_000_000, 64);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd24!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(10_000_000, 64);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd32!(svec)
@assert issorted(svec)


svec = DataBench.gen_string_vec_var_len(100_000_000, 64);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd16!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(100_000_000, 64);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd24!(svec)
@assert issorted(svec)

svec = DataBench.gen_string_vec_var_len(100_000_000, 64);
julia_lsd_radixsort_elapsed = @elapsed FastGroupBy.radixsort_lsd32!(svec)
@assert issorted(svec)