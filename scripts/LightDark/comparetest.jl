using ParticleFilters
using PFTDPW, POMCPOW

include(join([@__DIR__,"/../../src/benchmark2.jl"]))
include(join([@__DIR__,"/pomdp.jl"]))

pomdp = LightDarkPOMDP
times = Float64[0.01,0.05]
PFTDPW_params = Dict{Symbol,Any}(
    :c => 50.0,
    :k_o => 10.0,
    :k_a => 2.0,
    :n_particles => 100,
    :max_depth => 40
)

POMCPOW_params = Dict{Symbol,Any}(
    :criterion => MaxUCB(50.0),
    :k_observation => 10.0,
    :k_action => 2.0,
    :max_depth => 40,
    :default_action => (args...) -> rand(actions(pomdp))
)

solvers = [(PFTDPWSolver,"PFTDPW", PFTDPW_params),(POMCPOWSolver, "POMCPOW", POMCPOW_params)]
updater = BootstrapFilter(pomdp, 10_000)
max_steps = 50
N = 50

bb = BatchBenchmark(pomdp, times, solvers, updater, max_steps, N)

df = benchmark(bb)
