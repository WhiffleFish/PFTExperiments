using POMDPs
using POMDPSimulators
using DataFrames
using CSV

mutable struct BatchBenchmark # Parameterize
    pomdp::POMDP
    times::Vector{Float64}
    solvers::Vector{ Tuple{UnionAll, String, Dict{Symbol,Any}} } # (solver_type, solver_name, solver_params)
    updater::Updater
    max_steps::Int
    N::Int # number of times to repeat a simulation
end

function benchmark(bb::BatchBenchmark)
    tot_sims = length(bb.times)*length(bb.solvers)*bb.N
    rewards = Vector{Float64}(undef,tot_sims)
    sol_names = Vector{String}(undef,tot_sims)
    times = Vector{Float64}(undef,tot_sims)

    ro = RolloutSimulator(max_steps=bb.max_steps)

    i = 1
    for t in bb.times
        for (sol_t,name,p) in bb.solvers

            println("Solver: $sol_t")
            println("Planning Time: $t")

            solver = sol_t(; max_time=t, p...)
            planner = solve(solver, bb.pomdp)
            sim = POMDPSimulators.Sim(
                bb.pomdp,
                planner,
                bb.updater,
                max_steps=bb.max_steps,
                simulator=ro
            )
            sims = Sim[deepcopy(sim) for _ in 1:bb.N]
            res = run_parallel(sims, show_progress=true)

            rewards[i:(i+bb.N-1)] .= res.reward
            sol_names[i:(i+bb.N-1)] .= name
            times[i:(i+bb.N-1)] .= t
            i += bb.N
        end
    end
    return DataFrame(sol=sol_names,t=times,r=rewards)
end
