module ContObsExperiments
using POMDPs
using POMDPSimulators
using DataFrames
using Random
using CSV

include("benchmark.jl")
export BatchBenchmark, benchmark

using CairoMakie
using DataFrames
using Statistics
include("plot.jl")
export BenchmarkSummary
export SCRIPTS_PATH,
    BABY_DATA_PATH,
    LASERTAG_DATA_PATH,
    LIGHTDARK_DATA_PATH,
    SUBHUNT_DATA_PATH,
    VDPTAG_DATA_PATH

include(joinpath("LightDark", "LightDark.jl"))

include("combine.jl")

end
