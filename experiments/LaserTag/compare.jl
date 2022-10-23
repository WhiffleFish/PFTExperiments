using Distributed
using CSV
using Dates
using PFTBenchmarks
const COE = PFTBenchmarks

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@show length(procs())

Distributed.@everywhere begin
    using PFTBenchmarks
    using POMDPs
    using POMDPTools
    using ParticleFilters
    using ParticleFilterTrees, POMCPOW, BasicPOMCP
    const PFT = ParticleFilterTrees
    using AdaOPS
    using DiscreteValueIteration
    using LaserTag
    using QMDP

    import Distributions
    const pomdp = gen_lasertag()
    Distributions.support(::LaserTag.LTInitialBelief) = states(pomdp)
end


VE = FOValue(ValueIterationSolver())
PO_VE = PFT.PORollout(QMDPSolver(); n_rollouts=1)

times = args["test"] ? [0.1] : 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(25.18, inv(10.85)),
    :k_o => 5.22,
    :alpha_o => 0.33,
    :n_particles => 25,
    :max_depth => 48,
    :tree_queries => 1_000_000,
    :value_estimator => PO_VE,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

SparsePFT_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(15.48,inv(4.58)),
    :k_o => 15.5,
    :alpha_o => 0.0,
    :n_particles => 96,
    :max_depth => 37,
    :tree_queries => 1_000_000,
    :value_estimator => PO_VE,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

POMCPOW_params = Dict{Symbol,Any}(
    :criterion => MaxUCB(26.0),
    :max_depth => 50,
    :k_observation => 4.0,
    :alpha_observation => 1/35,
    :enable_action_pw => false,
    :check_repeat_obs => false,
    :tree_queries => 10_000_000,
    :estimate_value => VE,
    :default_action => (args...) -> rand(actions(pomdp))
)

POMCP_params = Dict{Symbol, Any}(
    :c => 26.0,
    :max_depth => 50,
    :tree_queries => 10_000_000,
    :default_action => (args...) -> rand(actions(pomdp))
)

AdaOPS_params = Dict{Symbol, Any}(
    :bounds => AdaOPS.IndependentBounds(
        BasicPOMCP.FORollout(RandomSolver()),
        AdaOPS.POValue(QMDPSolver()),
        check_terminal=true
    ),
    :timeout_warning_threshold => Inf,
    :default_action => (args...) -> rand(actions(pomdp))
)

solvers = [
    (PFTDPWSolver,"PFTDPW", PFTDPW_params),
    (PFTDPWSolver,"SparsePFT", SparsePFT_params)
    # (POMCPOWSolver, "POMCPOW", POMCPOW_params),
    # (POMCPSolver, "POMCP", POMCP_params),
    # (AdaOPSSolver, "AdaOPS", AdaOPS_params)
]

updater = DiscreteUpdater(pomdp)
max_steps = 50
N = args["test"] ? 5 : args["iter"]

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

rmprocs(p)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "compare"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
