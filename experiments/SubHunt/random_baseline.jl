using Distributed
using CSV
using Dates
using Random

worker_ids = Distributed.addprocs(20; exeflags="--project")

Distributed.@everywhere begin
    using POMDPs
    using POMDPSimulators
    using POMDPPolicies
    using SubHunt
end

using ContObsExperiments

pomdp = SubHuntPOMDP()

max_steps = 100
N = 5000

sol = RandomSolver()
policy = solve(sol, pomdp)
sim_vec = [
    POMDPSimulators.Sim(pomdp, policy; max_steps=max_steps, rng=MersenneTwister(rand(UInt32)))
    for _ in 1:N
]

df = run_parallel(sim_vec)

rmprocs(worker_ids)

date_str = Dates.format(now(), "_yyyy_mm_dd")
filename = "random"*date_str*".csv"
filepath = joinpath(@__DIR__, "data", filename)
CSV.write(filepath,df)
