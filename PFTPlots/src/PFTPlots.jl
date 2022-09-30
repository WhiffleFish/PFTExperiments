module PFTPlots

using CairoMakie
using ColorSchemes
using DataFrames
using Statistics

const PROJECT_ROOT          = abspath(joinpath(@__DIR__, "..", ".."))
const SCRIPTS_PATH          = joinpath(PROJECT_ROOT, "experiments")
const BABY_DATA_PATH        = joinpath(SCRIPTS_PATH, "Baby", "data")
const DVDPTAG_DATA_PATH     = joinpath(SCRIPTS_PATH, "DVDPTag", "data")
const LASERTAG_DATA_PATH    = joinpath(SCRIPTS_PATH, "LaserTag", "data")
const LIGHTDARK_DATA_PATH   = joinpath(SCRIPTS_PATH, "LightDark", "data")
const SUBHUNT_DATA_PATH     = joinpath(SCRIPTS_PATH, "SubHunt", "data")
const VDPTAG_DATA_PATH      = joinpath(SCRIPTS_PATH, "VDPTag", "data")

export SCRIPTS_PATH,
    BABY_DATA_PATH,
    LASERTAG_DATA_PATH,
    LIGHTDARK_DATA_PATH,
    SUBHUNT_DATA_PATH,
    DVDPTAG_DATA_PATH,
    VDPTAG_DATA_PATH

include("plot.jl")
export BenchmarkSummary, plot_data, plot_ax!

end
