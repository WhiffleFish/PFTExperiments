using Hyperopt
using PFTBenchmarks
const COE = PFTBenchmarks
using JLD2
using Plots

PROBLEMS = ["DVDPTag", "LaserTag", "LightDark", "SubHunt", "VDPTag"]
SOLVERS = ["PFTDPW", "SparsePFT"]
problem = "SubHunt"
solver = "SparsePFT"
ho = first(values(load("experiments/$problem/opt/data/$solver.jld2")))
h = Hyperoptimizer((getfield(ho, f) for f ∈ propertynames(ho))..., ()->())
p = plot(h)
savefig(p, "$(solver)_$(problem)_params.svg")

str = join(["$(lstrip(string(p), '_')), $v" for (p,v) ∈ zip(h.params, h.maximizer)], '\n')
file_path = joinpath(COE.PROJECT_ROOT, "hyperopt", "$(solver)_$(problem).csv")
open(file_path, "w") do file
    write(file, str)
end

h.maximum
h.params

for solver ∈ SOLVERS
    for problem ∈ PROBLEMS
        ho = first(values(load("experiments/$problem/opt/data/$solver.jld2")))
        h = Hyperoptimizer((getfield(ho, f) for f ∈ propertynames(ho))..., ()->())
        str = join(["$(lstrip(string(p), '_')), $v" for (p,v) ∈ zip(h.params, h.maximizer)], '\n')
        file_path = joinpath(COE.PROJECT_ROOT, "hyperopt", "$(solver)_$(problem).csv")
        open(file_path, "w") do file
            write(file, str)
        end
    end
end

join(["$(lstrip(string(p), '_')), $v" for (p,v) ∈ zip(h.params, h.maximizer)], '\n')

for (p,v) ∈ zip(h.params, h.maximizer)
    println(p,", ",round(v;sigdigits=3))
end


##

using ContObsExperiments
const COE = ContObsExperiments
using Plots

ho = COE.restore(joinpath(@__DIR__, "data", "POMCPOW.jld2"));
plot(ho)
@show ho.maximizer
@show ho.maximum


##
using VDPTag2
using POMDPs
using AdaOPS
using Random
using POMDPSimulators
using ParticleFilters
pomdp = ADiscreteVDPTagPOMDP(n_angles=20)

@code_warntype actiontype(supertype(typeof(cproblem(pomdp))))

f(p::POMDP) = actiontype(cproblem(pomdp))

@code_warntype f(pomdp)


sol = AdaOPSSolver(T_max = 0.1,timeout_warning_threshold=Inf)
planner = solve(sol, pomdp)
@time action(planner, initialstate(pomdp));
@profiler action(planner, initialstate(pomdp));

s = rand(initialstate(pomdp))
a = rand(actions(pomdp))
@code_warntype POMDPs.gen(pomdp, s, a, Random.GLOBAL_RNG)

@edit POMDPs.gen(pomdp, s, a, Random.GLOBAL_RNG)

o_type = @edit observation(pomdp, s, a, sp)

ro = RolloutSimulator(max_steps=20)
@profiler simulate(ro, pomdp, planner,BootstrapFilter(pomdp, 10_000))



using PFTDPW
sol = PFTDPWSolver(max_depth=6, k_o=4.0, alpha_o=0.19, c=47.0, n_particles=120, tree_queries = 1_000, max_time = 0.1)
planner = solve(sol, pomdp)

sims = [simulate(ro, pomdp, planner,BootstrapFilter(pomdp, 10_000)) for _ in 1:20]
mean(sims)

h = simulate(HistoryRecorder(max_steps=20), pomdp, planner, BootstrapFilter(pomdp, 10_000))

using Plots
plot(pomdp, h)


##
pomdp = VDPTagPOMDP()
sol = PFTDPWSolver(max_depth=6, k_o=4.0, alpha_o=0.19, c=47.0, k_a = 10.0, n_particles=120, tree_queries = 1_000, max_time = 0.1, enable_action_pw=true)
planner = solve(sol, pomdp)
h = simulate(HistoryRecorder(max_steps=20), pomdp, planner, BootstrapFilter(pomdp, 100))
getfield.(h.hist,:r)
plot(pomdp, h)

@time action(planner, initialstate(pomdp))
