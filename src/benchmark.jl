using POMDPModelTools
using POMDPModels
using POMDPSimulators
using ParticleFilters
using BeliefUpdaters
using ProgressMeter
using DataFrames
using POMDPs
using POMCPOW
using Plots
using CSV
using Setfield
include("/Users/tyler/Documents/code/PFTDPW.jl/src/PFTDPW.jl")

mutable struct BatchBenchmark
    pomdp::POMDP
    policies::Dict{Symbol, Policy}
    solvers::Dict{Symbol, Solver}
    updater::Updater
    max_steps::Int # Max number of steps for simulations to run
    N::Int
    times::Vector{Float64}
    results::Dict{Symbol,Dict{Float64, Vector{Float64}}}
end

function BatchBenchmark(pomdp::POMDP, solvers::Dict{Symbol, Solver}, max_steps::Int, N::Int, times::Vector{Float64}; updater::Updater=BootstrapFilter(pomdp,1_000))::BatchBenchmark
    policies = Dict{Symbol,Policy}(name=>solve(solver, pomdp) for (name,solver) in solvers)
    results = Dict{Symbol, Dict{Float64, Vector{Float64}}}(
        name=>Dict{Float64, Vector{Float64}}(t=>Vector{Float64}(undef, N) for t in times)
        for name in keys(policies)
        )
    return BatchBenchmark(pomdp, policies, solvers, updater, max_steps, N, times, results)
end

# function BatchBenchmark(pomdp::POMDP, policies::Dict{Symbol, Policy}, max_steps::Int, N::Int, times::Vector{Float64}; updater::Updater=BootstrapFilter(pomdp,1_000))::BatchBenchmark
#     results = Dict{Symbol, Dict{Float64, Vector{Float64}}}(
#         name=>Dict{Float64, Vector{Float64}}(t=>Vector{Float64}(undef, N) for t in times)
#         for name in keys(policies)
#         )
#     return BatchBenchmark(pomdp, policies, updater, max_steps, N, times, results)
# end

function set_attr(s::OBJ, attr::Symbol, val)::OBJ where OBJ
    d = Dict(name=>getfield(s,name) for name in fieldnames(OBJ))
    d[attr] = val
    args = [d[name] for name in fieldnames(OBJ)]
    return OBJ(args...)
end

function set_planner_time(planner::POMCPOWPlanner, t::Float64)
    sol = planner.solver
    sol = set_attr(sol, :max_time, t)
    set_attr(planner, :solver, sol)
end

function set_planner_time(planner::PFTDPWPlanner, t::Float64)
    sol = planner.sol
    sol = set_attr(sol, :max_time, t)
    set_attr(planner, :sol, sol)
end

# function set_planner_times!(BB::BatchBenchmark, t::Float64)
#     for (name, policy) in BB.policies
#         BB.policies[name] = set_planner_time(policy, t)
#     end
# end

function set_planner_times!(BB::BatchBenchmark, t::Float64)
    for (name, solver) in BB.solvers
        @set! solver.max_time = t
        BB.policies[name] = solve(solver, BB.pomdp)
    end
end

function benchmark!(BB::BatchBenchmark)::Nothing
    ro = RolloutSimulator(max_steps=BB.max_steps)
    upd = BB.updater
    l = length(BB.times)
    for (i,t) in enumerate(BB.times)
        println("($i/$l) \t t=$t")
        set_planner_times!(BB, t)
        @showprogress for j = 1:N
            for (name, planner) in BB.policies
                r = simulate(ro, BB.pomdp, planner, upd)
                BB.results[name][t][j] = r
            end
        end
    end
    return nothing
end

function DataFrame(BB::BatchBenchmark)
    results = BB.results
    df_dict = Dict{Symbol, Vector{Float64}}(
        :times=>sizehint!(Float64[],BB.N*length(BB.times)),
        (k=>sizehint!(Float64[],BB.N*length(BB.times)) for k in keys(results))...
        )
    for (name, t_dict) in results
        for time in BB.times
            push!(df_dict[name], results[name][time]...)
        end
    end
    for t in BB.times
        push!(df_dict[:times], repeat([t],BB.N)...)
    end

    return DataFrames.DataFrame(df_dict)
end

function Plots.histogram(BB::BatchBenchmark, t::Float64)
    vals = [BB.results[k][t] for k in keys(BB.results)]
    labels=reshape([String(name) for name in keys(BB.results)],1,length(BB.policies))
    histogram(vals, alpha=0.5, label=labels, normalize=true)
    xlabel!("Returns")
    ylabel!("Density")
end
