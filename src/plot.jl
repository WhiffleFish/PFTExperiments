set_theme!(Theme(fontsize=21, font="Times New Roman"))

const SCRIPTS_PATH = joinpath(PROJECT_ROOT, "scripts")
const BABY_DATA_PATH = joinpath(SCRIPTS_PATH, "Baby", "data")
const DVDPTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "DVDPTag", "data")
const LASERTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "LaserTag", "data")
const LIGHTDARK_DATA_PATH = joinpath(SCRIPTS_PATH, "LightDark", "data")
const SUBHUNT_DATA_PATH = joinpath(SCRIPTS_PATH, "SubHunt", "data")
const VDPTAG_DATA_PATH = joinpath(SCRIPTS_PATH, "VDPTag", "data")

const SOLVER_LINESTYLES = Dict{String, Any}(
    "SparsePFT" => nothing,
    "PFTDPW" => :dash,
    "POMCPOW" => :dot,
    "AdaOPS" => :dashdotdot,
    "POMCP" => :dashdot
)

const COLOR_SCHEME = if length(SOLVER_LINESTYLES) > 5
    ColorSchemes.rainbow[
    range(0.0, 1.0, length=length(SOLVER_LINESTYLES))]
else
    [
    ColorSchemes.RGB(202/255, 000/255, 230/255),
    ColorSchemes.RGB(230/255, 105/255, 023/255),
    ColorSchemes.RGB(000/255, 011/255, 230/255),
    ColorSchemes.RGB(126/255, 230/255, 023/255),
    ColorSchemes.RGB(000/255, 217/255, 230/255)
    ]
end

const SOLVER_COLORS = Dict{String, ColorSchemes.RGB{Float64}}(
    "SparsePFT" => COLOR_SCHEME[1],
    "PFTDPW" => COLOR_SCHEME[2],
    "POMCP" => COLOR_SCHEME[3],
    "POMCPOW" => COLOR_SCHEME[4],
    "AdaOPS" => COLOR_SCHEME[5]
)

const POMDP_NAMES = Dict{String, String}(
    "baby" => "Baby",
    "lightdark" => "LightDark",
    "lasertag" => "LaserTag",
    "subhunt" => "SubHunt",
    "vdptag" => "VDPTag"
)

struct BenchmarkSummary
    title::String
    data::DataFrame
    solvers::Vector{String}
    times::Vector{Float64}
end

function table_data(b::BenchmarkSummary, t::Float64=1.0; baseline=nothing, eps=0.0)
    df = b.data
    df = filter(:t => ==(t), df)
    df = select(df, Not(:t))

    if !isnothing(baseline)
        min_score = baseline
        max_score = maximum(df.mean)
        score_range = max_score - min_score
    else
        min_score, max_score = extrema(df.mean)
        score_range = max_score - min_score
        ϵ = eps*score_range
        min_score -= ϵ
        score_range += ϵ
    end

    colors = @. (df.mean - min_score) / score_range
    df[!,:color] = colors

    return df
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
    title = "Benchmark"
    for (k,v) in POMDP_NAMES
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
    line_arr = []
    for (i,(name, data)) in enumerate(df_data)
        color = SOLVER_COLORS[name]
        t, μ, σ = sort_data(data)
        l = lines!(
            t, μ,
            marker=:rect,
            color=color,
            linestyle=SOLVER_LINESTYLES[name]
        )
        b = band!(
            t, μ .- ci*σ, μ .+ ci*σ,
            color=(color,0.10)
        )
        push!(line_arr, [l,b])
    end
    if legend
        axislegend(
            axis, line_arr, [first(t) for t in df_data],
            position = :rb, labelsize=15, framevisible=true
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
