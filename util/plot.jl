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

function plot_data(b::BenchmarkSummary; ignore=[], ci::Number=2)
    data = b.data
    names = ["POMCPOW", "PFTDPW", "SparsePFT", "POMCP"]
    df_data = [
        (name, data[data.sol .== name,:]) for name in names if name ∉ ignore
    ]

    f = Figure()
    axis = Axis(
        f[1,1],
        title = b.title,
        xlabel = "Planning Time (s)",
        ylabel = "Discounted Reward",
        xscale = log10
    )

    line_arr = []
    for (name, data) in df_data
        t, μ, σ = sort_data(data)
        l = lines!(t, μ, marker=:rect)
        push!(line_arr, l)
        band!(t, μ .- ci*σ, μ .+ ci*σ)
    end
    axislegend(axis, line_arr, [first(t) for t in df_data], position = :lt)
    display(f)
    return f
end

## Example

filepath = joinpath(VDPTAG_DATA_PATH, "compare_2021_07_15.csv")
filepath = joinpath(LASERTAG_DATA_PATH, "compare_2021_10_03.csv")
filepath = joinpath(LIGHTDARK_DATA_PATH, "compare_2021_09_30.csv")
filepath = joinpath(SUBHUNT_DATA_PATH, "compare_2021_09_30.csv")

b = BenchmarkSummary(filepath)

f = plot_data(b, ignore=["POMCP"], ci=2)
