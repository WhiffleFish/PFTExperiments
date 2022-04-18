using Distributed
using CSV
using Dates
using Random

worker_ids = Distributed.addprocs(3; exeflags="--project")

Distributed.@everywhere begin
    using POMDPs
    using POMDPSimulators
    using POMDPPolicies
    using SubHunt
    using QMDP
    using Distributions
    using ParticleFilters
end

using ContObsExperiments

pomdp = SubHuntPOMDP()
b0 = initialstate(pomdp)

max_steps = 100
N = 5000

sol = QMDPSolver()
policy = solve(sol, pomdp)
sim_vec = [
    POMDPSimulators.Sim(
        pomdp,
        policy,
        BootstrapFilter(pomdp, 10_000),
        ParticleCollection([rand(b0) for _ in 1:10_000]);
        max_steps = max_steps,
        rng = MersenneTwister(rand(UInt32)))
    for _ in 1:N
]

df = run_parallel(sim_vec)

rmprocs(worker_ids)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "qmdp"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
