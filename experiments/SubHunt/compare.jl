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
    using ParticleFilterTrees, POMCPOW, BasicPOMCP
    using AdaOPS
    using DiscreteValueIteration
    using SubHunt
    using QMDP
    const pomdp = SubHuntPOMDP()
    # Distributions.support(::SubHunt.SubHuntInitDist) = ordered_states(pomdp)
end

const PFT = ParticleFilterTrees

VE = FOValue(ValueIterationSolver())
PO_VE = PFT.PORollout(QMDPSolver(); n_rollouts=1)

times = args["test"] ? [0.1] : 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(85.43, inv(11.83)),
    :k_o => 9.62,
    :alpha_o => 0.08,
    :n_particles => 79,
    :max_depth => 20,
    :tree_queries => 1_000_000,
    :value_estimator => PO_VE,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

SparsePFT_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(20.24, inv(3.95)),
    :k_o => 27.36,
    :alpha_o => 0.0,
    :n_particles => 23,
    :max_depth => 19,
    :tree_queries => 1_000_000,
    :value_estimator => PO_VE,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

POMCPOW_params = Dict{Symbol,Any}(
    :criterion => MaxUCB(17.0),
    :k_observation => 6.0,
    :alpha_observation => 1/100,
    :enable_action_pw => false,
    :check_repeat_obs => false,
    :tree_queries => 10_000_000,
    :estimate_value => VE,
    :default_action => (args...) -> rand(actions(pomdp))
)

POMCP_params = Dict{Symbol, Any}(
    :c => 17.0,
    :max_depth => 84,
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
    # (POMCPSolver, "POMCP", POMCP_params)
    # (AdaOPSSolver, "AdaOPS", AdaOPS_params)
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
