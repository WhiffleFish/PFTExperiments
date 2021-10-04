using Hyperopt
using Optim
using PFTDPW
using Plots
using QMDP

using Distributed
procs = Distributed.add_procs(40)
include("src/evaluate.jl")
include("scripts/LightDark/pomdp.jl")

pomdp = LightDarkPOMDP
bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(PFTDPWSolver, pomdp, 500, bu, 30)

η = 4
R = 100
s_max = floor(log(η,R))
total_resources = (s_max+1)^2*R

η = 3
R = 5
s_max = floor(log(η,R))
total_resources = (s_max+1)^2*R

bohb = @hyperopt for i=0,
        sampler=Hyperband(
            R=R,
            η=η,
            inner=BOHB(dims=[
                Hyperopt.Continuous(), Hyperopt.Continuous(),
                Hyperopt.Continuous(), Hyperopt.Continuous(),
                Hyperopt.Continuous()])),
        c = exp10.(LinRange(-1,3,100)),
        k_obs = Float64.(1:20),
        inv_alpha_obs = Float64.(10:40),
        max_depth = Float64.(10:100),
        n_ro = Float64.(1:20),
        n_p = exp10.(LinRange(0,3,100))

    n = 0
    μ = 0.0
    if !(state === nothing)
        n,μ,c,k_obs,inv_alpha_obs,max_depth,n_ro,n_p = state
    end

    params.n = floor(Int,i)
    @show params.n
    @show c
    @show k_obs
    @show inv_alpha_obs
    @show max_depth
    @show n_p

    res = evaluate(params;
        c = c,
        max_time = 0.10,
        tree_queries = 50_000,
        k_o = k_obs,
        alpha_o = inv(inv_alpha_obs),
        max_depth = floor(Int, max_depth),
        n_particles = floor(Int, n_p),
        enable_action_pw = false,
        check_repeat_obs = false,
        value_estimator = PFTDPW.PORollout(QMDPSolver(),Int(n_ro))
    )

    res = (n*μ + params.n*res)/(n+params.n)
    n += params.n
     # bohb finds minimizer so we look for minimizer of -res
    -res, (n, res, c, k_obs, inv_alpha_obs, max_depth, n_ro, n_p)
end

plot(bohb)

Distributed.rmprocs(procs)

PFTDPW.PORollout(QMDPSolver(), 1)
