using Distributed
using CSV
using Dates
using PFTBenchmarks
const COE = PFTBenchmarks

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

Distributed.@everywhere begin
    using PFTBenchmarks
    using POMDPs
    using POMDPTools
    using ParticleFilters
    using ParticleFilterTrees, POMCPOW, BasicPOMCP
    using PFTBenchmarks
    const PFT = ParticleFilterTrees
    using VDPTag2
    const pomdp = VDPTagPOMDP(mdp=VDPTagMDP(barriers=CardinalBarriers(0.2, 2.8)))
end

@show length(procs())

times = args["test"] ? [0.1] : 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(23.4, inv(4.07)),
    :k_o => 21.4,
    :k_a => 22.52,
    :alpha_o => 0.043,
    :alpha_a => 0.317,
    :n_particles => 132,
    :max_depth => 44,
    :tree_queries => 1_000_000,
    :check_repeat_obs => false,
    :enable_action_pw => true
)

SparsePFT_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(15.68, inv(8.15)),
    :k_o => 28.0,
    :k_a => 27.92,
    :alpha_o => 1/10,
    :alpha_a => 0.0,
    :n_particles => 385,
    :max_depth => 33,
    :tree_queries => 1_000_000,
    :check_repeat_obs => false,
    :enable_action_pw => true
)

POMCPOW_params = Dict{Symbol,Any}(
    :criterion => MaxUCB(110.0),
    :max_depth => 10,
    :k_observation => 5.0,
    :k_action => 30,
    :alpha_action => 1/30,
    :alpha_observation => 1/100,
    :enable_action_pw => true,
    :check_repeat_obs => false,
    :tree_queries => 10_000_000,
    :default_action => (args...) -> rand(actions(pomdp))
)

POMCP_params = Dict{Symbol, Any}(
    :c => 110.0,
    :max_depth => 84,
    :tree_queries => 10_000_000,
    :default_action => (args...) -> rand(actions(pomdp))
)

solvers = [
    (PFTDPWSolver,"PFTDPW", PFTDPW_params),
    (PFTDPWSolver,"SparsePFT", SparsePFT_params),
    (POMCPOWSolver, "POMCPOW", POMCPOW_params)
    # (POMCPSolver, "POMCP", POMCP_params)
]

updater = BootstrapFilter(pomdp, 100_000)
max_steps = 100
N = args["test"] ? 5 : args["iter"]

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

rmprocs(p)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "compare"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
