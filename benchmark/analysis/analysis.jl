using DataFrames, CSV

bpath  = "./benchmark/out/"
bfiles = readdir(bpath)
bfiles = setdiff(bfiles,["64", "old"])


@time bdf = CSV.read.(bpath .* bfiles)

hehe = r"(?<algo>sp|mrs|srg|srs)(?<tries>[0-9]+)"

hehe1  = match.(hehe, bfiles)

hehe2  = [hehe2.captures for hehe2 in hehe1]

hehe3 = [(hehe3[1], eval(parse(hehe3[2])) , bdf1[1,1]) for (hehe3, bdf1) in zip(hehe2,bdf)]

algo = [h[1] for h in hehe3]
n = [h[2] for h in hehe3]
elapsed = [h[3] for h in hehe3]

hehe4 = DataFrame(algo = algo, n = n, elapsed =  elapsed)

hehe5 = by(hehe4, [:algo, :n], df -> mean(df[:elapsed]))

sort!(hehe5, cols = [:algo,:n])

CSV.write(hehe5,"hehe5.csv")
