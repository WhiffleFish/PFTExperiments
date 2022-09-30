using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")

@everywhere begin
    using SubHunt
    using POMDPModelTools
    using Distributions
    using POMCPOW

    pomdp = SubHuntPOMDP()
end

search_iter = 200

bu = BootstrapFilter(pomdp, 100_000)
params = OptParams(POMCPOWSolver, pomdp, 200, bu, 100)

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
        max_time=1.0,
        k_observation=k_obs,
        alpha_observation=1/inv_alpha_obs,
        enable_action_pw=false,
        tree_queries=10_000_000,
        max_depth = Int(max_depth),
        default_action = (args...) -> rand(actions(pomdp))
    )
end

rmprocs(worker_ids)

save(join([@__DIR__,"/data/POMCPOW_params.jld2"]), Dict("ho"=>ho))
