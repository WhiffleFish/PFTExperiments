using Distributed
using Hyperopt

worker_ids = addprocs(10; exeflags="--project")

include("../../src/evaluate.jl")
@everywhere using PFTDPW

search_iter = 500

pomdp = BabyPOMDP()
k_a = length(actions(pomdp)) - 1

bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(PFTDPWSolver, pomdp, 500, bu, 20)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:5),
        inv_alpha_obs = Float64.(20:40),
        max_depth = Float64.(10:30)
    println("($i/$search_iter) \t c=$c")
    @show evaluate(params;
        c=c,
        max_time=0.10,
        tree_queries=100_000,
        k_o=k_obs,
        alpha_o=1/inv_alpha_obs,
        k_a = k_a,
        max_depth=Int(max_depth)
    )
end
rmprocs(worker_ids)
save("scripts/Baby/data/PFTDPW_params.jld2", Dict("ho"=>ho))
