using ContObsExperiments
using ContObsExperiments.LightDark
using POMDPs
using POMDPModelTools
using POMDPSimulators
using ParticleFilters
using QMDP
using BasicPOMCP
using AdaOPS
using POMDPPolicies

pomdp = LightDark.LightDarkPOMDP()

bnds = AdaOPS.IndependentBounds(
    BasicPOMCP.FORollout(RandomSolver()),
    AdaOPS.POValue(QMDPSolver()),
    check_terminal = true
)


sol = AdaOPSSolver(T_max = 0.1, bounds = bnds, timeout_warning_threshold=Inf)
planner = solve(sol, pomdp)

b0 = initialstate(pomdp)
action(planner, b0)

hr = HistoryRecorder(max_steps=50)
ro = RolloutSimulator(max_steps=50)


simulate(ro, pomdp, planner, BootstrapFilter(pomdp, 10_000))

h = simulate(hr, pomdp, planner, BootstrapFilter(pomdp, 10_000))
LightDark.LightDarkPlot(h)

@progress rew1 = [simulate(ro, pomdp, planner, BootstrapFilter(pomdp, 1000)) for _ in 1:100]

@progress rew2 = [simulate(ro, pomdp, planner, BootstrapFilter(pomdp, 1000)) for _ in 1:100]

violin([rew1, rew2], label="")
mean(rew1)
mean(rew2)
