using ContObsExperiments

filepath = joinpath(VDPTAG_DATA_PATH, "compare_2021_07_15.csv")
b1 = BenchmarkSummary(filepath)
f = ContObsExperiments.plot_data(b1, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","VDPTag_2021_07_15.svg"), f)


filepath = joinpath(LASERTAG_DATA_PATH, "compare_2021_10_03.csv")
b2 = BenchmarkSummary(filepath)
f = plot_data(b2, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","LaserTag_2021_07_15.svg"), f)


filepath = joinpath(LIGHTDARK_DATA_PATH, "compare_2021_09_30.csv")
b3 = BenchmarkSummary(filepath)
f = plot_data(b3, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","LightDark_2021_07_15.svg"), f)


filepath = joinpath(SUBHUNT_DATA_PATH, "compare_2021_09_30.csv")
b4 = BenchmarkSummary(filepath)
f = plot_data(b4, ignore=["POMCP"], ci=2)
save(joinpath(@__DIR__,"..","img","Subhunt_2021_07_15.svg"), f)

##

set_theme!(Theme(fontsize=14, font="Times New Roman"))

f = Figure()
plot_ax!(f[1,1], b1, ignore=["POMCP"]; legend=true, xlabel="")
plot_ax!(f[1,2], b2, ignore=["POMCP"]; legend=false, xlabel="", ylabel="")
plot_ax!(f[2,1], b3, ignore=["POMCP"]; legend=false)
plot_ax!(f[2,2], b4, ignore=["POMCP"]; legend=false, ylabel="")
display(f)
save(joinpath(@__DIR__,"..","img","all_plots.svg"), f)


##
filepath = joinpath(LIGHTDARK_DATA_PATH, "AdaOPS_2022_03_21.csv")
b = BenchmarkSummary(filepath)
f = plot_data(b, ci=2)
save(joinpath(@__DIR__,"..","img","LightDark_2021_03_21.svg"), f)
