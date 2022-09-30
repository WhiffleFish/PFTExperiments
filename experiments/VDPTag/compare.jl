using Distributed
using CSV
using Dates
using PFTBenchmarks
const COE = PFTBenchmarks

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

Distributed.@everywhere begin
    using POMDPs
    using POMDPSimulators
    using ParticleFilters
    using ParticleFilterTrees, POMCPOW, BasicPOMCP
    using VDPTag2
end

@show length(procs())

pomdp = VDPTagPOMDP(mdp=VDPTagMDP(barriers=CardinalBarriers(0.2, 2.8)))

times = 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxUCB(70.0),
    :k_o => 8.0,
    :k_a => 20.0,
    :alpha_o => 1/85,
    :alpha_a => 1/25,
    :n_particles => 20,
    :max_depth => 10,
    :tree_queries => 1_000_000,
    :check_repeat_obs => false,
    :enable_action_pw => true
)

SparsePFT_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxUCB(70.0),
    :k_o => 8.0,
    :k_a => 20.0,
    :alpha_o => 1/10,
    :alpha_a => 0.0,
    :n_particles => 20,
    :max_depth => 10,
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
N = args["iter"]

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

rmprocs(p)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "compare"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
