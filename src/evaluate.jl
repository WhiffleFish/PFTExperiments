using Distributed
using Hyperopt

@everywhere begin
    using Pkg
    Pkg.activate(".")
    Pkg.instantiate()
    using POMDPs
    using POMDPModels
    using BeliefUpdaters
    using ParticleFilters
    using POMDPSimulators
    using POMCPOW
end

struct OptParams{T<:Solver}
    sol_t::Type{T}
    pomdp::POMDP
    n::Int
    updater::Updater
    max_steps::Int
end

function evaluate(params::OptParams; kwargs...)
    solver = params.sol_t(;kwargs...)
    planner = solve(solver, params.pomdp)
    bu = params.updater
    sim = POMDPSimulators.Sim(params.pomdp, planner, bu, max_steps=params.max_steps)
    sims = Sim[deepcopy(sim) for _ in 1:params.n]
    res = run_parallel(sims, show_progress=true)
    return mean(res.reward)
end
