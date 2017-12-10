# sorting in data.frame is slow
if false
    N = 100_000_000
    K = 100
    using DataFrames
    srand(1)
    @time df = DataFrame(idstr = rand([@sprintf "id%03d" k for k in 1:(N/K)], N)
        , id = rand(1:K, N)
        , val = rand(1:5,N))

    @time sort!(df,cols=[:id, :val])


    using uCSV
    @time uCSV.write("df.csv", df);

    using CSV
    @time CSV.write("df.csv", df);
end
