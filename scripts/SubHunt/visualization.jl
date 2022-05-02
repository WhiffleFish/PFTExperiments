using SubHunt
using PFTDPW
using Plots
using POMDPs
using ParticleFilters
using POMDPSimulators
using QMDP

PO_VE = PFTDPW.PORollout(QMDPSolver(); n_rollouts=1)
pomdp = SubHuntPOMDP()
pf = BootstrapFilter(pomdp, 10_000)
sol = PFTDPWSolver(
    tree_queries=10_000,
    c = 100.,
    k_o = 2.0,
    alpha_o = 0.1,
    n_particles = 20,
    max_depth = 50,
    value_estimator = PO_VE,
    check_repeat_obs = false,
    enable_action_pw = false,
    max_time=0.1)
policy = solve(sol, pomdp)
b0 = initialize_belief(pf, initialstate(pomdp))

hr = HistoryRecorder(max_steps=30)
hist = simulate(hr, pomdp, policy, pf, b0)

anim = @animate for h ∈ hist.hist
    v = SubVis(pomdp, h);
    Plots.plot(v)
end

v = SubVis(pomdp, hist.hist[4]);
p = Plots.plot(v)
save(joinpath(COE.PROJECT_ROOT, "img", "subhunt_pftdpw_snapshot.pdf"), p)



gif(anim, joinpath(COE.PROJECT_ROOT, "img", "subhunt_pftdpw.gif"), fps = 2)
