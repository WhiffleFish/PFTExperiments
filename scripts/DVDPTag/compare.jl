using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using CSV
using Dates

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@show length(procs())

Distributed.@everywhere begin
    using POMDPs, POMDPSimulators, POMDPPolicies
    using ParticleFilters
    using PFTDPW, POMCPOW, BasicPOMCP, AdaOPS
    using VDPTag2

    const pomdp = ADiscreteVDPTagPOMDP(n_angles=20)
    # AdaOPS calls observation(pomdp, a, sp) on setup just to get type of obs dist
    is = initialstate(pomdp)
    s = rand(is)
    a = rand(actions(pomdp))
    sp = rand(is)
    POMDPs.observation(p::ADiscreteVDPTagPOMDP, a::Int, sp::TagState) = POMDPs.observation(p, s, a, sp)
end

times = 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :c => 47.0,
    :k_o => 4.0,
    :alpha_o => 0.19,
    :n_particles => 119,
    :max_depth => 10,
    :tree_queries => 1_000_000,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

SparsePFT_params = Dict{Symbol,Any}(
    :c => 61.0,
    :k_o => 10.0,
    :alpha_o => 0.0,
    :n_particles => 240,
    :max_depth => 10,
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
