using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")
@everywhere using PFTDPW
@everywhere using LaserTag

search_iter = 200

@everywhere pomdp = gen_lasertag()

bu = BootstrapFilter(pomdp, 100_000)
params = OptParams(PFTDPWSolver, pomdp, 500, bu, 40)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:20),
        k_act = Float64.(2:10),
        max_depth = Float64.(10:100),
        n_p = Float64.([10,20,50,100,500,1_000])
    println("($i/$search_iter) \t c=$c \t k_obs=$k_obs \t k_act=$k_act")
    @show evaluate(params;
        c=c,
        max_time=0.10,
        tree_queries=100_000,
        k_o=k_obs,
        alpha_o=0.0,
        k_a = k_act,
        alpha_a = 0.0,
        max_depth = Int(max_depth),
        n_particles = Int(n_p)
    )
end
rmprocs(worker_ids)

save(join([@__DIR__,"/data/SparsePFT_params.jld2"]), Dict("ho"=>ho))
