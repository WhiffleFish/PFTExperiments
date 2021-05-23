using Distributed
addprocs(2)

Distributed.@everywhere begin
    using POMDPs
    using POMDPModels
    using POMDPSimulators
    using POMCPOW
end

pomdp = BabyPOMDP()
solver = POMCPOWSolver(max_depth=20, max_time=0.1)
planner = solve(solver, pomdp)
upd = BootstrapFilter(pomdp, 1_000)
sims = Sim[Sim(pomdp, planner, upd ,max_steps=20) for _ in 1:100]

result = run_parallel(sims, show_progress=true)
