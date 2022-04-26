module ContObsExperiments
using POMDPs
using POMDPSimulators
using DataFrames
using ColorSchemes
using Random
using CSV
using Dates
using CairoMakie
using DataFrames
using Statistics
using FileIO
using Hyperopt
using ArgParse

const PROJECT_ROOT = pkgdir(ContObsExperiments)

include("benchmark.jl")
export BatchBenchmark, benchmark


include("plot.jl")
export BenchmarkSummary
export SCRIPTS_PATH,
    BABY_DATA_PATH,
    LASERTAG_DATA_PATH,
    LIGHTDARK_DATA_PATH,
    SUBHUNT_DATA_PATH,
    DVDPTAG_DATA_PATH,
    VDPTAG_DATA_PATH

include(joinpath("LightDark", "LightDark.jl"))

include("combine.jl")

include("evaluate.jl")

include("argparse.jl")

end
