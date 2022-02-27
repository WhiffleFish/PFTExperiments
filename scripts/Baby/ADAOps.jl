using POMDPs, POMDPModels, POMDPSimulators, AdaOPS

pomdp = BabyPOMDP()

solver = AdaOPSSolver(
    T_max=0.1,
    bounds=IndependentBounds(-20.0, 0.0),
    timeout_warning_threshold = 1.1)
planner = solve(solver, pomdp)
b0 = initialstate(pomdp)
s0 = rand(initialstate(pomdp))
a = rand(actions(pomdp))
action(planner, b0)
@gen(:sp, :o, :r)(pomdp, s0, a)

ro = RolloutSimulator(max_steps=10)

simulate(ro, pomdp, planner)


using BasicPOMCP
using DiscreteValueIteration
using QMDP
using ParticleFilters
using POMDPModelTools
using D3Trees
VE = FOValue(ValueIterationSolver())
PO_VE = BasicPOMCP.PORollout(QMDPSolver(),BootstrapFilter(pomdp, 1000))

b = AdaOPS.IndependentBounds(PO_VE, VE, check_terminal=true)
sol = AdaOPSSolver(T_max = 0.1, bounds=b, tree_in_info=false)
adaops = solve(sol, pomdp)
@time a, info = action_info(adaops, b0)

@benchmark action(adaops, b0)

@benchmark action(planner, b0)

@profiler for _ in 1:10; action(planner, b0); end

@edit action_info(planner, b0)
adaops.tree |> D3Tree |> inchrome



##
using JET
JET.@report_opt action(planner, b0)
