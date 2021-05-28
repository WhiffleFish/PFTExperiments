using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")

@everywhere begin
    using QuickPOMDPs
    using POMDPModelTools
    using Distributions
    using PFTDPW

    r = 60
    light_loc = 10

    pomdp = QuickPOMDP(
        states = -r:r+1, # r+1 is terminal
        actions = [-10, -1, 0, 1, 10],
        discount = 0.95,
        isterminal = s -> !(s in -r:r),
        obstype = Float64,

        transition = function (s, a)
            if a == 0
                return Deterministic(r+1)
            else
                return Deterministic(clamp(s+a, -r, r))
            end
        end,

        observation = (s, a, sp) -> Normal(sp, abs(sp - light_loc) + 0.0001),

        reward = function (s, a, sp, o)
            if a == 0
                return s == 0 ? 100 : -100
            else
                return -1.0
            end
        end,

        initialstate = POMDPModelTools.Uniform(div(-r,2):div(-r,2))
    )
end

search_iter = 200
bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(POMCPOWSolver, pomdp, 500, bu, 40)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:20),
        inv_alpha_obs = Float64.(10:40),
        k_act = Float64.(2:10),
        inv_alpha_act = Float64.(10:40),
        max_depth = Float64.(10:100)
    println("($i/$search_iter) \t c=$c \t k_obs=$k_obs \t k_act=$k_act")
    @show evaluate(params;
        criterion=MaxUCB(c),
        max_time=0.10,
        k_observation=k_obs,
        alpha_observation=1/inv_alpha_obs,
        k_action=k_act,
        alpha_action=1/inv_alpha_act,
        tree_queries=100_000,
        max_depth = Int(max_depth),
        default_action = (b,ex) -> rand(actions(pomdp))
    )
end

rmprocs(worker_ids)

save("scripts/LaserTag/data/POMCPOW_params.jld2", Dict("ho"=>ho))
