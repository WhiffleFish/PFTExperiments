using Distributed
worker_ids = add_procs(10)

include("../../src/evaluate.jl")

search_iter = 100

pomdp = BabyPOMDP()
bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(POMCPOWSolver, pomdp, 100, bu, 20)

ho = @hyperopt for i=1:search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:5),
        inv_alpha_obs = Float64.(20:40)
    println("($i/$search_iter) \t c=$c")
    @show evaluate(params;
        criterion=MaxUCB(c),
        max_time=0.10,
        k_observation=k_obs,
        alpha_obsvation=1/inv_alpha_obs
        enable_action_pw=false
    )
end

save("data/POMCPOW_params.jld2", Dict("ho"=>ho))
