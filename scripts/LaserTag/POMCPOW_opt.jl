using LaserTag
using Distributed

worker_ids = addprocs(10; exeflags="--project")

include("../../src/evaluate.jl")
@everywhere using POMCPOW

search_iter = 200

pomdp = gen_lasertag()
bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(POMCPOWSolver, pomdp, 500, bu, 40)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:20),
        inv_alpha_obs = Float64.(10:40),
        k_act = Float64.(2:10),
        inv_alpha_act = Float64.(10:40),
        max_depth = 10:100
    println("($i/$search_iter) \t c=$c \t k_obs=$k_obs \t k_act=$k_act")
    @show evaluate(params;
        criterion=MaxUCB(c),
        max_time=0.10,
        k_observation=k_obs,
        alpha_observation=1/inv_alpha_obs,
        k_action=k_act,
        alpha_action=1/inv_alpha_act,
        tree_queries=100_000,
        max_depth = max_depth
    )
end

rmprocs(worker_ids)

save("scripts/LaserTag/data/POMCPOW_params.jld2", Dict("ho"=>ho))
