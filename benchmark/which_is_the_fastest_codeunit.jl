# conclusion shortcircuit appears faster
const CHAR0 = Char(0)

function code_unit_if(str, pos)
    res = CHAR0
    if sizeof(str) > pos
        @inbounds res = codeunit(str, pos)
    end
    return res
end

function code_unit_short_circuit(str, pos)
    @inbounds return sizeof(str) >  pos ? CHAR0 :  res = codeunit(str, pos)
end

using DataBench, BenchmarkTools, Plots
gr()
a = DataBench.gen_string_vec_var_len(10_000_000, 8);

x = @belapsed code_unit_if.(a, 8)
y = @belapsed code_unit_short_circuit.(a, 8)
bar([x,y])

x = @belapsed code_unit_if.(a, 8)
y = @belapsed code_unit_short_circuit.(a, 8)
bar([x,y])