using Hyperopt
using FileIO
using Distributed

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using POMDPs
    using POMDPModels
    using BeliefUpdaters
    using ParticleFilters
    using POMDPSimulators
end

mutable struct OptParams{T<:Solver}
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
    sims = [POMDPSimulators.Sim(
        params.pomdp,
        planner,
        bu,
        max_steps=params.max_steps,
        simulator=RolloutSimulator(max_steps=params.max_steps))
        for _ in 1:params.n]
    res = run_parallel(sims, show_progress=true)
    return mean(res.reward)
end
