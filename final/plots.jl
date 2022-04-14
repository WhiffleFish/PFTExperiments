using ContObsExperiments
const COE = ContObsExperiments
using CairoMakie

set_theme!(Theme(fontsize=19, font="Times New Roman"))

b1 = BenchmarkSummary(COE.latest(LASERTAG_DATA_PATH, "compare"))
b2 = BenchmarkSummary(COE.latest(LIGHTDARK_DATA_PATH, "compare"))
b3 = BenchmarkSummary(COE.latest(SUBHUNT_DATA_PATH, "compare"))
b4 = BenchmarkSummary(COE.latest(VDPTAG_DATA_PATH, "compare"))

f = Figure()
COE.plot_ax!(f[1,1], b1, ignore=["POMCP"]; legend=true, xlabel="")
COE.plot_ax!(f[1,2], b2, ignore=["POMCP"]; legend=false, xlabel="", ylabel="")
COE.plot_ax!(f[2,1], b3, ignore=["POMCP"]; legend=false)
COE.plot_ax!(f[2,2], b4, ignore=["POMCP"]; legend=false, ylabel="")
display(f)
save(joinpath(COE.PROJECT_ROOT,"img","all_plots.pdf"), f)

##
f = COE.plot_data(b1, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","LaserTag_2021_07_15.svg"), f)

f = COE.plot_data(b2, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","LightDark_2021_07_15.svg"), f)

f = COE.plot_data(b3, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","Subhunt_2021_07_15.svg"), f)

f = COE.plot_data(b4, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","VDPTag_2021_07_15.svg"), f)


##
COE.table_data(b4)

#=
f1 = COE.latest(SUBHUNT_DATA_PATH, "compare")
f2 = joinpath(SUBHUNT_DATA_PATH, "compare_2021_09_30.csv")
df1 = DataFrame(CSV.File(f1))

df = COE.combinedf(f1, df1.sol |> unique, f2, ["POMCP"])

CSV.write(f1, df)

b1
=#
