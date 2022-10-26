using PFTPlots
const PFT = PFTPlots
using PFTBenchmarks
using CairoMakie

FONT = "Times New Roman"
FONTSIZE = 14
XLABEL = "Planning Time (sec)"
YLABEL = "Reward"
IGNORE = ["POMCP"]

set_theme!(Theme(fontsize=FONTSIZE, font=FONT))

b1 = BenchmarkSummary(PFT.latest(LASERTAG_DATA_PATH, "compare"))
b2 = BenchmarkSummary(PFT.latest(LIGHTDARK_DATA_PATH, "compare"))
b3 = BenchmarkSummary(PFT.latest(SUBHUNT_DATA_PATH, "compare"))
b4 = BenchmarkSummary(PFT.latest(VDPTAG_DATA_PATH, "compare"))
b5 = BenchmarkSummary(PFT.latest(DVDPTAG_DATA_PATH, "compare"))


size_inches = (8.3, 6.5)
size_pt = 72 .* size_inches
begin # This is positively horrific
    f = Figure(resolution = size_pt, fontsize = FONTSIZE)
    ax1, line_dict = PFT.plot_ax!(f[1,1], b1; ignore=IGNORE, legend=false, xlabel="", ylabel=YLABEL, ret_data=true, titlefont=FONT, xticklabelsvisible=false)
    PFT.plot_ax!(f[1,2], b2; ignore=IGNORE, legend=false, xlabel="", ylabel="", titlefont=FONT, xticklabelsvisible=false)
    PFT.plot_ax!(f[1,3], b3; ignore=IGNORE, legend=false, xlabel="", ylabel="", titlefont=FONT)
    PFT.plot_ax!(f[2,1], b4; ignore=IGNORE, legend=false, xlabel="", ylabel=YLABEL, titlefont=FONT)
    PFT.plot_ax!(f[2,2], b5; ignore=IGNORE, legend=false, xlabel="", ylabel="", title="Discrete VDP Tag", limits = (0.01, 1.0, -10, nothing), titlefont=FONT)
    Legend(f[2,3], collect(values(line_dict)), collect(keys(line_dict)))
    for i in 1:3
        ax = Axis(f[3,i])
        hidedecorations!(ax)
        hidespines!(ax)
        text!(XLABEL, ax, textsize=FONTSIZE, font=FONT, align=(:center,:bottom))
    end
    for i in 1:3; colsize!(f.layout, i, Aspect(1, 1.0)); end
    rowsize!(f.layout, 3, Fixed(30))
    display(f)
end

save(joinpath(PFT.PROJECT_ROOT,"img","all_plots.svg"), f)

##

size_inches = (4, 3)
size_pt = 72 .* size_inches
f = Figure(resolution = size_pt, fontsize = 12)
save("figure.pdf", f, pt_per_unit = 1)


##
f = PFT.plot_data(b1, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","LaserTag_2021_07_15.pdf"), f)

f = PFT.plot_data(b2, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","LightDark_2021_07_15.pdf"), f)

f = PFT.plot_data(b3, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","Subhunt_2021_07_15.pdf"), f)

f = PFT.plot_data(b4, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","VDPTag_2021_07_15.pdf"), f)

f = PFT.plot_data(b5, ignore=["POMCP"], ci=2)
save(joinpath(COE.PROJECT_ROOT,"img","DVDPTag_2022_04_27.pdf"), f)

## extra

COE.plot_data(b4)
COE.plot_data(b5)

COE.table_data(b4)
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

b = BenchmarkSummary(COE.latest(COE.SUBHUNT_DATA_PATH, "SparsePFT"))

sort(b.data, :t)

m_min = -14.86
m_max = 61.7
(m - m_min) / (m_max - m_min)


df = COE.latest(COE.DVDPTAG_DATA_PATH, "random") |> CSV.File |> DataFrame
df.reward |> mean
std(df.reward) / √length(df.reward)


##
using CSV
problem = "LightDark"
fp1 = "/Users/tyler/code/PFTExperiments/experiments/$problem/data/compare_2022_04_08.csv"
fp2 = "/Users/tyler/code/PFTExperiments/experiments/$problem/data/compare_2022_10_23.csv"
df = PFT.combinedf(fp1, ("AdaOPS", "POMCPOW"), fp2, ("PFTDPW", "SparsePFT"))

CSV.write("/Users/tyler/code/PFTExperiments/experiments/$problem/data/compare_2022_10_25.csv", df)
