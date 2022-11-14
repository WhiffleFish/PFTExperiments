using PFTBenchmarks
const COE = PFTBenchmarks
using Distributed
using CSV
using Dates

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@show length(procs())

Distributed.@everywhere begin
    using POMDPs, POMDPTools
    using PFTBenchmarks
    using ParticleFilters
    using ParticleFilterTrees, POMCPOW, BasicPOMCP, AdaOPS
    const PFT = ParticleFilterTrees
    using VDPTag2

    const pomdp = ADiscreteVDPTagPOMDP(cpomdp=VDPTagPOMDP(mdp=VDPTagMDP(barriers=CardinalBarriers(0.2, 2.8))), n_angles=20)
    # AdaOPS calls observation(pomdp, a, sp) on setup just to get type of obs dist
    is = initialstate(pomdp)
    s = rand(is)
    a = rand(actions(pomdp))
    sp = rand(is)
    POMDPs.observation(p::ADiscreteVDPTagPOMDP, a::Int, sp::TagState) = POMDPs.observation(p, s, a, sp)
end

times = args["test"] ? [0.1] : 10.0 .^ (-2:0.25:0)

PFTDPW_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(10.32, inv(5.48)),
    :k_o => 9.23,
    :alpha_o => 0.11,
    :n_particles => 330,
    :max_depth => 22,
    :tree_queries => 1_000_000,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

SparsePFT_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(76.2, inv(12.81)),
    :k_o => 25.0,
    :alpha_o => 0.0,
    :n_particles => 444,
    :max_depth => 46,
    :tree_queries => 1_000_000,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

POMCPOW_params = Dict{Symbol,Any}(
    :criterion => MaxUCB(31.0),
    :max_depth => 10,
    :k_observation => 12.0,
    :alpha_observation => 0.05,
    :enable_action_pw => false,
    :check_repeat_obs => false,
    :tree_queries => 10_000_000,
    :default_action => (args...) -> rand(actions(pomdp))
)

AdaOPS_params = Dict{Symbol, Any}(
    :bounds => AdaOPS.IndependentBounds(
        BasicPOMCP.FORollout(RandomSolver()),
        1e6),
    :m_min => 40.0,
    :delta => 0.25,
    :timeout_warning_threshold => Inf,
    :default_action => (args...) -> rand(actions(pomdp))
)

solvers = [
    (PFTDPWSolver,"PFTDPW", PFTDPW_params),
    (PFTDPWSolver,"SparsePFT", SparsePFT_params),
    (POMCPOWSolver, "POMCPOW", POMCPOW_params),
    (AdaOPSSolver, "AdaOPS", AdaOPS_params)
]

updater = BootstrapFilter(pomdp, 200_000)
max_steps = 100
N = args["test"] ? 5 : args["iter"]

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

rmprocs(p)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "compare"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath, df)
