using ContObsExperiments
const COE = ContObsExperiments

p1 = joinpath(LIGHTDARK_DATA_PATH, "compare_2021_09_30.csv")
p2 = joinpath(LIGHTDARK_DATA_PATH, "AdaOPS_2022_04_08.csv")

b = BenchmarkSummary(p2)
COE.plot_data(b)



df = COE.combinedf(p1,["POMCPOW", "PFTDPW", "SparsePFT"], p2, ["AdaOPS"])

using CSV
CSV.write("compare_2022_04_08.csv",df)

p_final = joinpath(LIGHTDARK_DATA_PATH, "compare_2022_04_08.csv")

b = BenchmarkSummary(p_final)
COE.plot_data(b)

##

p1 = joinpath(LASERTAG_DATA_PATH, "compare_2021_10_03.csv")
p2 = joinpath(LASERTAG_DATA_PATH, "AdaOPS_2022_04_09.csv")

b = BenchmarkSummary(p1)
COE.plot_data(b)



df = COE.combinedf(p1,["POMCPOW", "PFTDPW", "SparsePFT"], p2, ["AdaOPS"])

using CSV
CSV.write("compare_2022_04_09.csv",df)

p_final = joinpath(LASERTAG_DATA_PATH, "compare_2022_04_09.csv")

b = BenchmarkSummary(p_final)
COE.plot_data(b)

##

p1 = joinpath(SUBHUNT_DATA_PATH, "compare_2021_09_30.csv")
p2 = joinpath(SUBHUNT_DATA_PATH, "AdaOPS_2022_04_08.csv")

b = BenchmarkSummary(p2)
COE.plot_data(b)



df = COE.combinedf(p1,["POMCPOW", "PFTDPW", "SparsePFT"], p2, ["AdaOPS"])

using CSV
CSV.write("compare_2022_04_09.csv",df)

p_final = joinpath(SUBHUNT_DATA_PATH, "compare_2022_04_09.csv")

b = BenchmarkSummary(p_final)
COE.plot_data(b)
