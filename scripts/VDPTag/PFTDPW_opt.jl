using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")

@everywhere begin
    using QuickPOMDPs
    using POMDPModelTools
    using Distributions
    using VDPTag2
    using PFTDPW

    pomdp = VDPTagPOMDP()
end

search_iter = 50

bu = BootstrapFilter(pomdp, 100_000)
params = OptParams(PFTDPWSolver, pomdp, 500, bu, 50)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:100),
        inv_alpha_obs = Float64.(10:50),
        k_act = Float64.(1:50),
        inv_alpha_act = Float64.(10:50),
        max_depth = Float64.(10:100),
        n_p = Float64.(100:100:1_000)
    println("($i/$search_iter) \t c=$c \t k_obs=$k_obs \t k_act=$k_act \t n_p=$n_p")
    @show evaluate(params;
        c=c,
        max_time=1.0,
        tree_queries=1_000_000,
        k_o=k_obs,
        alpha_o=1/inv_alpha_obs,
        k_a = k_act,
        alpha_a = 1/inv_alpha_act,
        max_depth = Int(max_depth),
        n_particles = Int(n_p)
    )
end
rmprocs(worker_ids)
save("scripts/VDPTag/data/PFTDPW_params.jld2", Dict("ho"=>ho))
