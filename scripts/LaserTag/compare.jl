using Distributed
using CSV
using Dates
using ContObsExperiments
const COE = ContObsExperiments

p = addprocs(args["addprocs"]; exeflags="--project")

@show length(procs())

Distributed.@everywhere begin
    using POMDPs
    using POMDPSimulators
    using ParticleFilters
    using POMDPPolicies
    using PFTDPW, POMCPOW, BasicPOMCP
    using AdaOPS
    using DiscreteValueIteration
    using LaserTag
    using QMDP
end

pomdp = gen_lasertag()
VE = FOValue(ValueIterationSolver())
PO_VE = PFTDPW.PORollout(QMDPSolver(); n_rollouts=1)

times = 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :c => 26.0,
    :k_o => 4.0,
    :alpha_o => 1/35,
    :n_particles => 20,
    :max_depth => 50,
    :tree_queries => 1_000_000,
    :value_estimator => PO_VE,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

SparsePFT_params = Dict{Symbol,Any}(
    :c => 26.0,
    :k_o => 4.0,
    :k_a => 9.0,
    :alpha_o => 0.0,
    :alpha_a => 0.0,
    :n_particles => 20,
    :max_depth => 50,
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
    # (PFTDPWSolver,"PFTDPW", PFTDPW_params),
    # (PFTDPWSolver,"SparsePFT", SparsePFT_params)
    # (POMCPOWSolver, "POMCPOW", POMCPOW_params),
    # (POMCPSolver, "POMCP", POMCP_params),
    (AdaOPSSolver, "AdaOPS", AdaOPS_params)
]

updater = BootstrapFilter(pomdp, 500_000)
max_steps = 50
N = args["test"] ? args["iter"] : 5000

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

rmprocs(p)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "compare"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
