using ContObsExperiments
const COE = ContObsExperiments
using CairoMakie

set_theme!(Theme(fontsize=19, font="Times New Roman"))

b1 = BenchmarkSummary(COE.latest(LASERTAG_DATA_PATH, "compare"))
b2 = BenchmarkSummary(COE.latest(LIGHTDARK_DATA_PATH, "compare"))
b3 = BenchmarkSummary(COE.latest(SUBHUNT_DATA_PATH, "compare"))
b4 = BenchmarkSummary(COE.latest(VDPTAG_DATA_PATH, "compare"))
b5 = BenchmarkSummary(COE.latest(DVDPTAG_DATA_PATH, "compare"))

f = Figure()
ax1,line_dict = COE.plot_ax!(f[1,1], b1, ignore=["POMCP"]; legend=false, xlabel="Planning Time (sec)", ret_data=true)
COE.plot_ax!(f[1,2], b2, ignore=["POMCP"]; legend=false, xlabel="Planning Time (sec)", ylabel="")
COE.plot_ax!(f[1,3], b3, ignore=["POMCP"]; legend=false, xlabel="Planning Time (sec)", ylabel="")
COE.plot_ax!(f[2,1], b4, ignore=["POMCP"]; legend=false, xlabel="Planning Time (sec)")
COE.plot_ax!(f[2,2], b5, ignore=["POMCP"]; legend=false, xlabel="Planning Time (sec)", ylabel="", title="Discrete VDPTag", limits = (0.01, 1.0, -10, nothing))
Legend(f[2,3], collect(values(line_dict)), collect(keys(line_dict)))
for i in 1:3; colsize!(f.layout, i, Aspect(1, 1.0)); end
display(f)
save(joinpath(COE.PROJECT_ROOT,"img","all_plots.pdf"), f)

##
f = COE.plot_data(b1, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","LaserTag_2021_07_15.pdf"), f)

f = COE.plot_data(b2, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","LightDark_2021_07_15.pdf"), f)

f = COE.plot_data(b3, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","Subhunt_2021_07_15.pdf"), f)

f = COE.plot_data(b4, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","VDPTag_2021_07_15.pdf"), f)

f = COE.plot_data(b5, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","DVDPTag_2022_04_27.pdf"), f)

##
COE.table_data(b5)



sort(filter(:sol => ==("SparsePFT"), b5.data), :t)
sort(filter(:sol => ==("PFTDPW"), b5.data), :t)

sort(filter(:sol => ==("POMCPOW"), b5.data), :t)


(2.0 - -66.8) / (24.5 - -66.8)

#=
f1 = COE.latest(SUBHUNT_DATA_PATH, "compare")
f2 = joinpath(SUBHUNT_DATA_PATH, "compare_2021_09_30.csv")
df1 = DataFrame(CSV.File(f1))

df = COE.combinedf(f1, df1.sol |> unique, f2, ["POMCP"])

CSV.write(f1, df)

b1
=#

using DataFrames
using Statistics
using CSV

df = COE.latest(COE.SUBHUNT_DATA_PATH, "SparsePFT") |> CSV.File |> DataFrame
m = mean(df.r)
std(df.reward) / sqrt(length(df.reward))
# wtf is POMCP actually doing in VDPTag??? -> random default action

b = BenchmarkSummary(COE.latest(COE.SUBHUNT_DATA_PATH, "SparsePFT"))

sort(b.data, :t)

m_min = -14.86
m_max = 61.7
(m - m_min) / (m_max - m_min)


df = COE.latest(COE.DVDPTAG_DATA_PATH, "random") |> CSV.File |> DataFrame
df.reward |> mean
std(df.reward) / √length(df.reward)
