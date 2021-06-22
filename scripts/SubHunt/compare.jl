using Distributed
using CSV

worker_ids = Distributed.addprocs(20; exeflags="--project")

Distributed.@everywhere begin
    using ParticleFilters
    using PFTDPW, POMCPOW, BasicPOMCP
    using SubHunt
    include(join([@__DIR__,"/../../src/benchmark2.jl"]))
end

include(join([@__DIR__,"/../../util/restore.jl"]))
ho_pft = RestoreHopt(join([@__DIR__,"/data/PFTDPW_params.jld2"]))
ho_sparsepft = RestoreHopt(join([@__DIR__,"/data/SparsePFT_params.jld2"]))
ho_pomcpow = RestoreHopt(join([@__DIR__,"/data/POMCPOW_params.jld2"]))
ho_pomcp = RestoreHopt(join([@__DIR__,"/data/BasicPOMCP_params.jld2"]))
pft_params = Dict(a=>b for (a,b) in zip(ho_pft.params, ho_pft.maximizer))
sparsepft_params = Dict(a=>b for (a,b) in zip(ho_sparsepft.params, ho_sparsepft.maximizer))
pomcpow_params = Dict(a=>b for (a,b) in zip(ho_pomcpow.params, ho_pomcpow.maximizer))
pomcp_params = Dict(a=>b for (a,b) in zip(ho_pomcp.params, ho_pomcp.maximizer))

pomdp = SubHuntPOMDP()
times = 10.0 .^ (-2:0.25:0)
PFTDPW_params = Dict{Symbol,Any}(
    :c => 100.0,
    :k_o => 2.0,
    :k_a => 4.0,
    :alpha_o => 1/10,
    :alpha_a => 0.0,
    :n_particles => 20,
    :max_depth => 50,
    :tree_queries => 1_000_000,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

SparsePFT_params = Dict{Symbol,Any}(
    :c => 100.0,
    :k_o => 2.0,
    :k_a => 4.0,
    :alpha_o => 1/10,
    :alpha_a => 0.0,
    :n_particles => 20,
    :max_depth => 50,
    :tree_queries => 1_000_000,
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
    :default_action => (args...) -> rand(actions(pomdp))
)

POMCP_params = Dict{Symbol, Any}(
    :c => 17.0,
    :max_depth => 84,
    :tree_queries => 10_000_000,
    :default_action => (args...) -> rand(actions(pomdp))
)

solvers = [
    (PFTDPWSolver,"PFTDPW", PFTDPW_params),
    (PFTDPWSolver,"SparsePFT", SparsePFT_params),
    (POMCPOWSolver, "POMCPOW", POMCPOW_params),
    (POMCPSolver, "POMCP", POMCP_params)
]

updater = BootstrapFilter(pomdp, 100_000)
max_steps = 100
N = 100

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)

rmprocs(worker_ids)

CSV.write(join([@__DIR__,"/data/compare.csv"]), df)
