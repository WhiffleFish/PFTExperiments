using Distributed
worker_ids = addprocs(10; exeflags="--project")

include("../../src/evaluate.jl")
@everywhere using PFTDPW
@everywhere using LaserTag

search_iter = 200

pomdp = BabyPOMDP()
k_a = length(actions(pomdp)) - 1

bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(PFTDPWSolver, pomdp, 500, bu, 40)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:20),
        inv_alpha_obs = Float64.(10:40),
        k_act = Float64.(2:10),
        inv_alpha_act = Float64.(10:40),
        max_depth = Float64.(10:100)
    println("($i/$search_iter) \t c=$c")
    @show evaluate(params;
        c=c,
        max_time=0.10,
        tree_queries=100_000,
        k_o=k_obs,
        alpha_o=1/inv_alpha_obs,
        k_a = k_act,
        alpha_a = 1/inv_alpha_a,
        max_depth = Int(max_depth)
    )
end
rmprocs(worker_ids)
save("scripts/LaserTag/data/PFTDPW_params.jld2", Dict("ho"=>ho))
