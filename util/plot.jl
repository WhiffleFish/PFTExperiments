using CairoMakie
using CSV
using DataFrames
using Statistics

SCRIPTS_PATH = joinpath(@__DIR__, "..", "scripts")
BABY_DATA_PATH = joinpath(SCRIPTS_PATH, "Baby", "data")
LASERTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "LaserTag", "data")
LIGHTDARK_DATA_PATH = joinpath(SCRIPTS_PATH, "LightDark", "data")
SUBHUNT_DATA_PATH = joinpath(SCRIPTS_PATH, "SubHunt", "data")
VDPTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "VDPTag", "data")

struct BenchmarkSummary
    title::String
    data::DataFrame
    solvers::Vector{String}
    times::Vector{Float64}
end

function BenchmarkSummary(path::String, title::String)
    df = DataFrame(CSV.File(path))
    times = unique(df.t)
    solvers = unique(df.sol)
    N = first(size(df))/(length(solvers)*length(times))

    plot_df = DataFrame(sol=String[], t=Float64[], mean=Float64[], stder=Float64[])
    for sol in solvers
        for t in times
            data = df[(df.sol .== sol) .* (df.t .== t), :].r
            mean = Statistics.mean(data)
            stder = Statistics.std(data)/sqrt(N)
            push!(plot_df, [sol, t, mean, stder])
        end
    end
    return BenchmarkSummary(title, plot_df, solvers, times)
end

function BenchmarkSummary(path::String)
    l_path = lowercase(path)
    name_dict = Dict(
        "baby" => "Baby",
        "lightdark" => "LightDark",
        "lasertag" => "LaserTag",
        "subhunt" => "SubHunt",
        "vdptag" => "VDPTag"
    )
    title = "Benchmark"
    for (k,v) in name_dict
        if occursin(k,l_path)
            title = "$v Benchmark"
            break
        end
    end
    return BenchmarkSummary(path,title)
end

function sort_data(data::DataFrame)
    t_unsorted, μ_unsorted, σ_unsorted = data.t, data.mean, data.stder
    p = sortperm(t_unsorted)
    t = t_unsorted[p]
    μ = μ_unsorted[p]
    σ = σ_unsorted[p]
    return t, μ, σ
end

function plot_ax!(f::GridPosition, b::BenchmarkSummary; ignore=[], ci::Number=2, legend=true)
    data = b.data
    names = ["POMCPOW", "PFTDPW", "SparsePFT", "POMCP"]
    df_data = [
        (name, data[data.sol .== name,:]) for name in names if name ∉ ignore
    ]

    axis = Axis(
        f,
        title = b.title,
        xlabel = "Planning Time (sec) - Log Scale",
        ylabel = "Reward",
        xscale = log10,
        xticks = 10. .^ [-2,-1,0],
        xminorticksvisible = true,
        xminorgridvisible = true,
        xminorticks = IntervalsBetween(9),
        limits = (0.01, 1.0, nothing, nothing)
    )
    color_dict = Dict{String, Symbol}(
        "POMCPOW" => :blue,
        "PFTDPW" => :orange,
        "SparsePFT" => :green,
        "POMCP" => :purple
    )
    line_arr = []
    for (name, data) in df_data
        color = color_dict[name]
        t, μ, σ = sort_data(data)
        l = lines!(t, μ, marker=:rect, color=color, linestyle=:dash)
        b = band!(t, μ .- ci*σ, μ .+ ci*σ, color=(color,0.5))
        push!(line_arr, [l,b])
    end
    if legend
        axislegend(
            axis, line_arr, [first(t) for t in df_data],
            position = :lt, labelsize=10, framevisible=true
        )
    end
    return axis
end

function plot_data(b::BenchmarkSummary; ignore=[], ci::Number=2)
    f = Figure()
    ax = plot_ax!(f[1,1], b; ignore=ignore, ci=ci, legend=true)
    display(f)
    return f
end

## Example

filepath = joinpath(VDPTAG_DATA_PATH, "compare_2021_07_15.csv")
b1 = BenchmarkSummary(filepath)
f = plot_data(b1, ignore=["POMCP"], ci=2)
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
plot_ax!(f[1,1], b1, ignore=["POMCP"]; legend=true)
plot_ax!(f[1,2], b2, ignore=["POMCP"]; legend=false)
plot_ax!(f[2,1], b3, ignore=["POMCP"]; legend=false)
plot_ax!(f[2,2], b4, ignore=["POMCP"]; legend=false)
display(f)
save(joinpath(@__DIR__,"..","img","all_plots.svg"), f)
