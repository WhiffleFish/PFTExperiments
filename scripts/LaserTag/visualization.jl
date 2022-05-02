using LaserTag
using PFTDPW
using Plots
using POMDPs
using ParticleFilters
using POMDPSimulators
using QMDP

PO_VE = PFTDPW.PORollout(QMDPSolver(); n_rollouts=1)
pomdp = gen_lasertag()
pf = BootstrapFilter(pomdp, 10_000)
sol = PFTDPWSolver(
    tree_queries=10_000,
    c = 26.,
    k_o = 4.0,
    alpha_o = 1/35,
    n_particles = 20,
    max_depth = 50,
    value_estimator = PO_VE,
    check_repeat_obs = false,
    enable_action_pw = false,
    max_time=1.0)
policy = solve(sol, pomdp)
b0 = initialize_belief(pf, initialstate(pomdp))

hr = HistoryRecorder(max_steps=30)
hist = simulate(hr, pomdp, policy, pf, b0)

h = hist.hist[10]
(;s,a,o,b,r) = h

# observation vis broken -> should be `s .- 0.5` in source code, but instead is `s - 0.5`
v = LaserTagVis(pomdp, a, r, s, nothing, b);
tikz_pic(v)


s.robot .- 0.5

anim = @animate for h ∈ hist.hist
    (;s,a,o,b,r) = h
    v = LaserTagVis(pomdp, s, a, o, b, r);
    tikz_pic(v)
end



##
using LaserTag
using POMDPGifs
using QMDP
using Random
using ParticleFilters

rng = MersenneTwister(7)

m = gen_lasertag(rng=rng, robot_position_known=true)
policy = solve(QMDPSolver(verbose=true), m)
filter = SIRParticleFilter(m, 10_000, rng=rng)

# MethodError: no method matching -(::StaticArrays.SVector{2, Int64}, ::Float64)
# lasertag package should be using broadcasted subtraction
@show makegif(m, policy, filter, filename="out.gif", rng=rng)
