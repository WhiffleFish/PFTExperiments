using Distributed
using POMDPModels
using Dates
using CSV

worker_ids = Distributed.addprocs(20; exeflags="--project")

Distributed.@everywhere begin
    using POMDPs
    using POMDPSimulators
    using ParticleFilters
    using PFTDPW, POMCPOW, BasicPOMCP
end

include(joinpath(@__DIR__,"../../src/benchmark.jl"))

#=
include(join([@__DIR__,"/../../util/restore.jl"]))
ho_pft = RestoreHopt(join([@__DIR__,"/data/PFTDPW_params.jld2"]))
ho_pomcpow = RestoreHopt(join([@__DIR__,"/data/POMCPOW_params.jld2"]))
ho_pomcp = RestoreHopt(join([@__DIR__,"/data/BasicPOMCP_params.jld2"]))
pft_params = Dict(a=>b for (a,b) in zip(ho_pft.params, ho_pft.maximizer))
pomcpow_params = Dict(a=>b for (a,b) in zip(ho_pomcpow.params, ho_pomcpow.maximizer))
pomcp_params = Dict(a=>b for (a,b) in zip(ho_pomcp.params, ho_pomcp.maximizer))
=#

pomdp = BabyPOMDP()
times = 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :c => 93.0,
    :k_o => 4.0,
    :k_a => 2.0,
    :alpha_o => 1/23,
    :n_particles => 100,
    :tree_queries => 1_000_000,
    :max_depth => 10,
    :enable_action_pw => false
)

POMCPOW_params = Dict{Symbol,Any}(
    :criterion => MaxUCB(50.0),
    :k_observation => 2.0,
    :alpha_observation => 1/21,
    :enable_action_pw => false,
    :tree_queries => 10_000_000,
    :default_action => (args...) -> rand(actions(pomdp))
)

POMCP_params = Dict{Symbol, Any}(
    :c => 74.0,
    :max_depth => 12,
    :tree_queries => 10_000_000,
    :default_action => (args...) -> rand(actions(pomdp))
)

solvers = [
    (PFTDPWSolver,"PFTDPW", PFTDPW_params),
    (POMCPOWSolver, "POMCPOW", POMCPOW_params),
    (POMCPSolver, "POMCP", POMCP_params)
]

updater = BootstrapFilter(pomdp, 10_000)
max_steps = 50
N = 1000

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "compare"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
