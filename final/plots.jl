using ContObsExperiments
const COE = ContObsExperiments

filepath = COE.latest(LASERTAG_DATA_PATH, "compare")
b1 = BenchmarkSummary(filepath)
f = COE.plot_data(b1, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","LaserTag_2021_07_15.svg"), f)


filepath = COE.latest(LIGHTDARK_DATA_PATH, "compare")
b2 = BenchmarkSummary(filepath)
f = COE.plot_data(b2, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","LightDark_2021_07_15.svg"), f)


filepath = COE.latest(SUBHUNT_DATA_PATH, "compare")
b3 = BenchmarkSummary(filepath)
f = COE.plot_data(b3, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","Subhunt_2021_07_15.svg"), f)

filepath = COE.latest(VDPTAG_DATA_PATH, "compare")
b4 = BenchmarkSummary(filepath)
f = COE.plot_data(b4, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","VDPTag_2021_07_15.svg"), f)

##
using CairoMakie

set_theme!(Theme(fontsize=14, font="Times New Roman"))

f = Figure()
COE.plot_ax!(f[1,1], b1, ignore=["POMCP"]; legend=true, xlabel="")
COE.plot_ax!(f[1,2], b2, ignore=["POMCP"]; legend=false, xlabel="", ylabel="")
COE.plot_ax!(f[2,1], b3, ignore=["POMCP"]; legend=false)
COE.plot_ax!(f[2,2], b4, ignore=["POMCP"]; legend=false, ylabel="")
display(f)
save(joinpath(@__DIR__,"..","img","all_plots.svg"), f)


##
filepath = joinpath(LIGHTDARK_DATA_PATH, "AdaOPS_2022_03_21.csv")
b = BenchmarkSummary(filepath)
f = plot_data(b, ci=2)
save(joinpath(@__DIR__,"..","img","LightDark_2021_03_21.svg"), f)
