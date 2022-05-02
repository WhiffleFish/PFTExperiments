using ContObsExperiments.LightDark
using ContObsExperiments
const COE = ContObsExperiments
using POMDPSimulators
using ParticleFilters
using POMDPs
using Statistics
using Plots

pomdp = LightDark.LightDarkPOMDP()
sol = LightDark.LightSteerSolver()
planner = solve(sol, pomdp)

hr = HistoryRecorder(max_steps = 20)
ro = RolloutSimulator(max_steps = 20)
b0 = initialstate(pomdp)
hist = simulate(hr, pomdp, planner, BootstrapFilter(pomdp, 100_000))
fig = LightDark.LightDarkPlot(hist)
savefig(fig, joinpath(COE.PROJECT_ROOT, "img", "EX_LIGHTDARK3.pdf"))
N = 5000
rewards = [simulate(ro, pomdp, planner, BootstrapFilter(pomdp, 10_000)) for _ in 1:N]
mean(rewards)
std(rewards) / sqrt(N)

Y = -10:30
m = LightDark.lightmap(hist, Y=Y)
heatmap(0:(length(hist)-1), Y,  m, c=:greys, legend=:none)
