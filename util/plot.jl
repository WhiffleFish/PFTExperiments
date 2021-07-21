using Gadfly
using CSV
using DataFrames
using Statistics
using ColorTypes

Gadfly.push_theme(:dark)

SCRIPTS_PATH = joinpath(@__DIR__, "../scripts")
BABY_DATA_PATH = joinpath(SCRIPTS_PATH, "Baby/data")
LASERTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "LaserTag/data")
LIGHTDARK_DATA_PATH = joinpath(SCRIPTS_PATH, "LightDark/data")
SUBHUNT_DATA_PATH = joinpath(SCRIPTS_PATH, "SubHunt/data")
VDPTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "VDPTag/data")

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

    plot_df = DataFrame(sol=String[], t=Float64[], mean=Float64[], stder=Float64[], ymin=Float64[], ymax=Float64[])
    for sol in solvers
        for t in times
            data = df[(df.sol .== sol) .* (df.t .== t), :].r
            mean = Statistics.mean(data)
            stder = Statistics.std(data)/sqrt(N)
            push!(plot_df, [sol, t, mean, stder, mean-stder, mean+stder])
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

function Gadfly.plot(b::BenchmarkSummary)
    layer1 = layer(x=:t, ymin=:ymin, ymax=:ymax, color=:sol, Geom.ribbon, Theme(default_color=RGB(1,1,1)), alpha=[0.60])
    layer2 = layer(x=:t, y=:mean, color=:sol, Geom.point, Geom.line)
    tmin, tmax = extrema(b.times)
    return plot(
        b.data,
        layer2,
        layer1,
        Coord.Cartesian(xmin=log10(tmin),xmax=log10(tmax)),
        Scale.x_log10,
        Guide.xlabel("Planning Time (s)"),
        Guide.ylabel("Reward"),
        Guide.title(b.title),
        Guide.colorkey(title="Solver"))
end


## Example

#=
filepath = joinpath(SUBHUNT_DATA_PATH, "compare_2021_07_21.csv")

b = BenchmarkSummary(filepath, "LightDark Benchmark")
b = BenchmarkSummary(filepath)

p = plot(b)

draw(SVG(7.5inch, 5inch), p)
=#
