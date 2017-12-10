using FastGroupBy
const M = 100_000_000 # data.table takes 12 seconds
const K = 100
srand(1)
const svec = rand(["id"*dec(k,10) for k in 1:M÷K], M)
