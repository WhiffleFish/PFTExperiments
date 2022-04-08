const SCRIPTS_PATH = joinpath(@__DIR__, "..", "scripts")
const BABY_DATA_PATH = joinpath(SCRIPTS_PATH, "Baby", "data")
const LASERTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "LaserTag", "data")
const LIGHTDARK_DATA_PATH = joinpath(SCRIPTS_PATH, "LightDark", "data")
const SUBHUNT_DATA_PATH = joinpath(SCRIPTS_PATH, "SubHunt", "data")
const VDPTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "VDPTag", "data")

const LINESTYLES = [nothing, :dash, :dot, :dashdot, :dashdotdot]

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
            data = df[(df.sol .== sol) .* (df.t .≈  t), :].r
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

function plot_ax!(f::GridPosition, b::BenchmarkSummary; ignore=[], ci::Number=2, legend=true, kwargs...)
    data = b.data
    names = b.solvers # ["POMCPOW", "PFTDPW", "SparsePFT", "POMCP", "AdaOPS"]
    df_data = [
        (name, data[data.sol .== name,:]) for name in names if (name ∉ ignore)
    ]

    axis = Axis(
        f;
        title = b.title,
        xlabel = "Planning Time (sec) - Log Scale",
        ylabel = "Reward",
        xscale = log10,
        xticks = exp10.([-2,-1,0]),
        xminorticksvisible = true,
        xminorgridvisible = true,
        xminorticks = IntervalsBetween(9),
        limits = (0.01, 1.0, nothing, nothing),
        kwargs...
    )
    color_dict = Dict{String, Symbol}(
        "POMCPOW" => :blue,
        "PFTDPW" => :orange,
        "SparsePFT" => :green,
        "POMCP" => :purple,
        "AdaOPS" => :yellow
    )
    line_arr = []
    for (i,(name, data)) in enumerate(df_data)
        color = color_dict[name]
        t, μ, σ = sort_data(data)
        l = lines!(t, μ, marker=:rect, color=color, linestyle=LINESTYLES[i])
        b = band!(t, μ .- ci*σ, μ .+ ci*σ, color=(color,0.25))
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