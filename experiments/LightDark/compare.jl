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
    using AdaOPS
    using DiscreteValueIteration
    using PFTBenchmarks.LightDark
    using QMDP
end

const PFT = ParticleFilterTrees

using PFTBenchmarks.LightDark

const pomdp = LightDark.LightDarkPOMDP()
VE = FOValue(ValueIterationSolver())
PO_VE1 = ParticleFilterTrees.PORollout(QMDPSolver(); n_rollouts=2)
PO_VE2 = ParticleFilterTrees.PORollout(QMDPSolver(); n_rollouts=4)

times = args["test"] ? [0.1] : 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(92.86, inv(3.34)),
    :k_o => 13.15,
    :alpha_o => 0.08,
    :n_particles => 33,
    :max_depth => 20,
    :tree_queries => 100_000,
    :value_estimator => PO_VE1,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

SparsePFT_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(95.43, inv(2.56)),
    :k_o => 24.16,
    :alpha_o => 1/10,
    :alpha_a => 0.0,
    :n_particles => 134,
    :max_depth => 28,
    :tree_queries => 100_000,
    :value_estimator => PO_VE2,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

POMCPOW_params = Dict{Symbol,Any}(
    :criterion => MaxUCB(90.0),
    :k_observation => 5.0,
    :alpha_observation => 1/15,
    :enable_action_pw => false,
    :check_repeat_obs => false,
    :tree_queries => 10_000_000,
    :estimate_value => VE,
    :default_action => (args...) -> rand(actions(pomdp))
)

POMCP_params = Dict{Symbol, Any}(
    :c => 83.0,
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
    (PFTDPWSolver,"SparsePFT", SparsePFT_params),
    (POMCPOWSolver, "POMCPOW", POMCPOW_params),
    (POMCPSolver, "POMCP", POMCP_params),
    (AdaOPSSolver, "AdaOPS", AdaOPS_params)
]

updater = BootstrapFilter(pomdp, 10_000)
max_steps = 30
N = args["test"] ? 5 : args["iter"]

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

rmprocs(p)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "compare"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
