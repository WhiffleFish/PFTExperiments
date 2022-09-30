using ContObsExperiments
const COE = ContObsExperiments
using Plots

path = joinpath(@__DIR__, "data", "VanillaSparsePFT.jld2")
ho = COE.restore(path);
ho |> plot

ho.maximizer

LinRange{Float64}

using FileIO
using JLD2
JLD2.load(path)["ho"]

using Base
LinRange{Float64}(5.0, 50.0, 100, 99)
range(10,100,length=50)
