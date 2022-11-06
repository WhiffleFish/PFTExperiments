using PFTBenchmarks
const COE = PFTBenchmarks
using Distributed
using FileIO, JLD2
using DelimitedFiles

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@info "SparsePFT LightDark ablation"
@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using PFTBenchmarks.LightDark
    using ParticleFilterTrees
    const PFT = ParticleFilterTrees
    using POMDPTools
    using POMDPs
    using QMDP
    const pomdp = LightDark.LightDarkPOMDP()
end

const ITER = args["test"] ? 2 : args["iter"]
const MAX_PARTICLES = args["test"] ? 50 : 500
const TREE_QUERIES = 1_000

const PO_VE = PFT.PORollout(QMDPSolver(); n_rollouts=4)

const SparsePFT_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(15.48,inv(4.58)),
    :k_o => 15.5,
    :alpha_o => 0.0,
    :max_depth => 37,
    :value_estimator => PO_VE,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

params = COE.OptParams(
    PFTDPWSolver,
    pomdp,
    args["test"] ? 5 : 500,
    DiscreteUpdater(pomdp),
    20
)

particles = round.(Int,logspace(1, MAX_PARTICLES, ITER)) |> unique
vals = zeros(Float64, length(particles))
std_errs = zeros(Float64, length(particles))

#=
using POMDPTools
sol = PFTDPWSolver(;tree_queries=1000, n_particles=500, SparsePFT_params...)
planner = solve(sol, pomdp)
b0 = initialstate(pomdp)
@time action_info(planner, b0)
=#

for i ∈ eachindex(particles, vals, std_errs)
    println("\n$i / $(length(particles))")
    μ, σ = COE.evaluate(
        params;
        ret_stderr = true,
        verbose = true,
        tree_queries = TREE_QUERIES,
        n_particles = particles[i],
        SparsePFT_params...
    )
    vals[i] = μ
    std_errs[i] = σ
end

Distributed.rmprocs(p)

path = joinpath(@__DIR__, "data", "SparsePFT.csv")

open(path, "w") do io
    write(io, "particles, reward, stderr\n")
    writedlm(io, [particles vals std_errs])
end
