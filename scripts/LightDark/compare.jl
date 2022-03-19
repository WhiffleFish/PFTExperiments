using Distributed
using CSV
using Dates

worker_ids = Distributed.addprocs(40; exeflags="--project")

Distributed.@everywhere begin
    using POMDPs
    using POMDPSimulators
    using ParticleFilters
    # using PFTDPW, POMCPOW, BasicPOMCP
    using AdaOPS
    using DiscreteValueIteration
    include(join([@__DIR__,"/pomdp.jl"]))
    using QMDP
end

include(joinpath(@__DIR__,"../../src/benchmark.jl"))

#=
include(join([@__DIR__,"/../../util/restore.jl"]))
ho_pft = RestoreHopt(join([@__DIR__,"/data/PFTDPW_params.jld2"]))
ho_sparsepft = RestoreHopt(join([@__DIR__,"/data/SparsePFT_params.jld2"]))
ho_pomcpow = RestoreHopt(join([@__DIR__,"/data/POMCPOW_params.jld2"]))
ho_pomcp = RestoreHopt(join([@__DIR__,"/data/BasicPOMCP_params.jld2"]))
pft_params = Dict(a=>b for (a,b) in zip(ho_pft.params, ho_pft.maximizer))
sparsepft_params = Dict(a=>b for (a,b) in zip(ho_sparsepft.params, ho_sparsepft.maximizer))
pomcpow_params = Dict(a=>b for (a,b) in zip(ho_pomcpow.params, ho_pomcpow.maximizer))
pomcp_params = Dict(a=>b for (a,b) in zip(ho_pomcp.params, ho_pomcp.maximizer))
=#

pomdp = LightDarkPOMDP
VE = FOValue(ValueIterationSolver())
PO_VE = PFTDPW.PORollout(QMDPSolver(),0)

times = 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :c => 100.0,
    :k_o => 4.0,
    :k_a => 4.0,
    :alpha_o => 1/10,
    :alpha_a => 0.0,
    :n_particles => 20,
    :max_depth => 20,
    :tree_queries => 100_000,
    :value_estimator => PO_VE,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

SparsePFT_params = Dict{Symbol,Any}(
    :c => 100.0,
    :k_o => 4.0,
    :k_a => 4.0,
    :alpha_o => 1/10,
    :alpha_a => 0.0,
    :n_particles => 20,
    :max_depth => 20,
    :tree_queries => 100_000,
    :value_estimator => PO_VE,
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
        BasicPOMCP.PORollout(QMDPSolver(), BootstrapFilter(pomdp, 20)),
        VE,
        check_terminal=true
    ),
    :timeout_warning_threshold => 2.0,
    :default_action => (args...) -> rand(actions(pomdp))
)

solvers = [
    # (PFTDPWSolver,"PFTDPW", PFTDPW_params),
    # (PFTDPWSolver,"SparsePFT", SparsePFT_params),
    # (POMCPOWSolver, "POMCPOW", POMCPOW_params),
    # (POMCPSolver, "POMCP", POMCP_params)
    (AdaOPSSolver, "AdaOPS", AdaOPS_params)
]

updater = BootstrapFilter(pomdp, 10_000)
max_steps = 30
N = 1000

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

rmprocs(worker_ids)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "compare"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
