struct BatchBenchmark{UPD<:Updater}
    pomdp::POMDP
    times::Vector{Float64} # planning times
    solvers::Vector{ Tuple{UnionAll, String, Dict{Symbol,Any}} } # (solver_type, solver_name, solver_params)
    updater::UPD # sim belief updater
    max_steps::Int # max sim steps
    N::Int # number of times to repeat a simulation
end

function benchmark(bb::BatchBenchmark; shuffle::Bool=true)
    shuffle ? shuffled_benchmark(bb) : unshuffled_benchmark(bb)
end

function unshuffled_benchmark(bb::BatchBenchmark)
    tot_sims = length(bb.times)*length(bb.solvers)*bb.N
    rewards = Vector{Float64}(undef,tot_sims)
    sol_names = Vector{String}(undef,tot_sims)
    times = Vector{Float64}(undef,tot_sims)

    i = 1
    for t in bb.times
        for (sol_t,name,p) in bb.solvers

            println("Solver: $name")
            println("Planning Time: $t")

            try
                solver = sol_t(; max_time=t, p...)
            catch
                solver = sol_t(; T_max=t, p...)
            end
            planner = solve(solver, bb.pomdp)
            sims = [POMDPSimulators.Sim(
                bb.pomdp,
                planner,
                bb.updater,
                max_steps=bb.max_steps,
                simulator=RolloutSimulator(max_steps=bb.max_steps, rng = MersenneTwister(rand(UInt32)))
            ) for _ in 1:bb.N]
            res = run_parallel(sims, show_progress=true)

            rewards[i:(i+bb.N-1)] .= res.reward
            sol_names[i:(i+bb.N-1)] .= name
            times[i:(i+bb.N-1)] .= t
            i += bb.N
        end
    end
    return DataFrame(sol=sol_names,t=times,r=rewards)
end

function shuffled_benchmark(bb::BatchBenchmark)
    tot_sims = length(bb.times)*length(bb.solvers)*bb.N
    sims = Vector{Sim}(undef,tot_sims)
    sol_names = Vector{String}(undef,tot_sims)
    times = Vector{Float64}(undef,tot_sims)

    i = 1
    for t in bb.times
        for (sol_t,name,p) in bb.solvers

            solver = try sol_t(; max_time=t, p...)
            catch
                sol_t(; T_max=t, p...)
            end
            planner = solve(solver, bb.pomdp)
            cur_sims = [POMDPSimulators.Sim(
                bb.pomdp,
                planner,
                bb.updater,
                max_steps=bb.max_steps,
                simulator=RolloutSimulator(max_steps=bb.max_steps, rng = MersenneTwister(rand(UInt32)))
            ) for _ in 1:bb.N]

            sims[i:(i+bb.N-1)] .= cur_sims
            sol_names[i:(i+bb.N-1)] .= name
            times[i:(i+bb.N-1)] .= t
            i += bb.N
        end
    end

    perm_arr = randperm(tot_sims)
    sims = sims[perm_arr]
    sol_names = sol_names[perm_arr]
    times = times[perm_arr]

    res = run_parallel(sims, show_progress=true)
    rewards = res.reward

    return DataFrame(sol=sol_names,t=times,r=rewards)
end
