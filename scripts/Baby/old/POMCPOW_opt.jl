using Distributed

worker_ids = addprocs(10; exeflags="--project")

include("../../src/evaluate.jl")
@everywhere using POMCPOW

search_iter = 500

pomdp = BabyPOMDP()
bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(POMCPOWSolver, pomdp, 500, bu, 20)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:5),
        inv_alpha_obs = Float64.(20:40)
    println("($i/$search_iter) \t c=$c")
    @show evaluate(params;
        criterion=MaxUCB(c),
        max_time=0.10,
        k_observation=k_obs,
        alpha_observation=1/inv_alpha_obs,
        tree_queries=100_000,
        enable_action_pw=false
    )
end
rmprocs(worker_ids)

save(join([@__DIR__,"/data/POMCPOW_params.jld2"]), Dict("ho"=>ho))
