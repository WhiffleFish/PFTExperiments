function combinedf(fp1::String, s1, fp2::String, s2)
    df1 = DataFrame(CSV.File(fp1))
    df2 = DataFrame(CSV.File(fp2))

    bv1 = falses(size(df1,1))
    bv2 = falses(size(df2,1))

    for s in s1
        bv1 .+= df1.sol .== s
    end
    idx1 = BitVector(min.(bv1, 1))
    for s in s2
        bv2 .+= df2.sol .== s
    end
    idx2 = BitVector(min.(bv2, 1))

    return vcat(df1[idx1,:], df2[idx2,:])
end

#=
fp1 = joinpath(LASERTAG_DATA_PATH, "compare_2021_10_01.csv")
fp2 = joinpath(LASERTAG_DATA_PATH, "compare_2021_09_30.csv")

df_new = combinedf(fp1, ["POMCPOW", "POMCP"], fp2, ["PFTDPW", "SparsePFT"])

new_filepath = joinpath(LASERTAG_DATA_PATH, "compare_2021_10_03.csv")

CSV.write(new_filepath, df_new)

b = BenchmarkSummary(new_filepath)
p = plot(b)
draw(SVG(7.5inch, 5inch), p)
=#
