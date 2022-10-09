mutable struct OptParams{T<:Solver, P<:POMDP, UPD<:Updater}
    sol_t::Type{T}
    pomdp::P
    n::Int
    updater::UPD
    max_steps::Int
end

function evaluate(params::OptParams; verbose::Bool=false, kwargs...)
    N = params.n
    solver = params.sol_t(;kwargs...)
    planner = solve(solver, params.pomdp)
    bu = params.updater
    sims = [POMDPTools.Sim(
        params.pomdp,
        planner,
        bu,
        max_steps = params.max_steps,
        simulator = RolloutSimulator(max_steps=params.max_steps))
        for _ in 1:N]
    res = run_parallel(sims, show_progress=true)
    μ = mean(res.reward)
    σ = std(res.reward)
    if verbose
        @show μ
        @show σ/√N
    end
    return μ
end

#=
"""
Hyperopt macro stores objective as anonymous function, which breaks save with JLD2
-> Restored version builds everything but field :objective
-> :objective filed inconsequential when looking at data so replace with ()->()
"""
function restore(path)
    d = FileIO.load(path)
    ho = first(values(d))
    h = Hyperoptimizer((getfield(ho,f) for f in propertynames(ho))..., ()->())
    return h
end
=#
