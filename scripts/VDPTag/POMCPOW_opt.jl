using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")

@everywhere begin
    using QuickPOMDPs
    using POMDPModelTools
    using Distributions
    using VDPTag2
    using POMCPOW

    pomdp = VDPTagPOMDP()
end

search_iter = 50

bu = BootstrapFilter(pomdp, 100_000)
params = OptParams(POMCPOWSolver, pomdp, 500, bu, 50)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:100),
        inv_alpha_obs = Float64.(10:50),
        k_act = Float64.(2:10),
        inv_alpha_act = Float64.(10:50),
        max_depth = Float64.(10:100)
    println("($i/$search_iter) \t c=$c \t k_obs=$k_obs \t k_act=$k_act")
    @show evaluate(params;
        criterion=MaxUCB(c),
        max_time=1.0,
        k_observation=k_obs,
        alpha_observation=1/inv_alpha_obs,
        k_action=k_act,
        alpha_action=1/inv_alpha_act,
        tree_queries=100_000,
        max_depth = Int(max_depth),
        default_action = (args...) -> rand(actions(pomdp))
    )
end

rmprocs(worker_ids)

save("scripts/VDPTag/data/POMCPOW_params.jld2", Dict("ho"=>ho))
