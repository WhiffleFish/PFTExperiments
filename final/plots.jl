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
save(joinpath(@__DIR__,"..","img","all_plots.pdf"), f)

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
using DataFrames
using CSV
baseline = DataFrame(CSV.File(COE.latest(LIGHTDARK_DATA_PATH, "random"))).reward |> mean

COE.table_data(b2; baseline=baseline)
