using PFTBenchmarks
const COE = PFTBenchmarks
using Distributed
using FileIO, JLD2
using DelimitedFiles

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@info "SparsePFT Discrete VDPTag ablation"
@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using PFTBenchmarks
    using VDPTag2
    using ParticleFilterTrees
    const PFT = ParticleFilterTrees
    using ParticleFilters
    using POMDPs
    const pomdp = ADiscreteVDPTagPOMDP(cpomdp=VDPTagPOMDP(mdp=VDPTagMDP(barriers=CardinalBarriers(0.2, 2.8))), n_angles=20)
end

const ITER = args["test"] ? 2 : args["iter"]
const TREE_QUERIES = 100

params = COE.OptParams(
    PFTDPWSolver,
    pomdp,
    args["test"] ? 5 : 250,
    BootstrapFilter(pomdp, 100_000),
    20
)

const SparsePFT_params = Dict{Symbol,Any}(
    :criterion => PFT.MaxPoly(76.2, inv(12.81)),
    :k_o => 25.0,
    :alpha_o => 0.0,
    :max_depth => 46,
    :check_repeat_obs => false,
    :enable_action_pw => false
)

const MAX_PARTICLES = args["test"] ? 50 : 500

particles = round.(Int,logspace(1, MAX_PARTICLES, ITER)) |> unique
vals = zeros(Float64, length(particles))
std_errs = zeros(Float64, length(particles))

#=
using POMDPTools
sol = PFTDPWSolver(;tree_queries=100, max_time=5.0,n_particles=500, SparsePFT_params...)
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
