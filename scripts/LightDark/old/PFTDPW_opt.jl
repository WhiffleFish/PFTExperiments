using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")

@everywhere begin
    using QuickPOMDPs
    using POMDPModelTools
    using Distributions
    using PFTDPW

    include(join([@__DIR__,"/pomdp.jl"]))
    pomdp = LightDarkPOMDP
end

search_iter = 200

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
        max_depth = Float64.(10:100),
        n_p = Float64.([10,20,50,100,500,1_000])
    println("($i/$search_iter) \t c=$c \t k_obs=$k_obs \t k_act=$k_act \t n_p=$n_p")
    @show evaluate(params;
        c=c,
        max_time=0.10,
        tree_queries=100_000,
        k_o=k_obs,
        alpha_o=1/inv_alpha_obs,
        k_a = k_act,
        alpha_a = 1/inv_alpha_act,
        max_depth = Int(max_depth),
        n_particles = Int(n_p)
    )
end
rmprocs(worker_ids)
save(join([@__DIR__,"/data/PFTDPW_params.jld2"]), Dict("ho"=>ho))