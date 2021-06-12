using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")

@everywhere begin
    using QuickPOMDPs
    using POMDPModelTools
    using Distributions
    using VDPTag2
    using BasicPOMCP

    pomdp = VDPTagPOMDP()
end

search_iter = 50

bu = BootstrapFilter(pomdp, 100_000)
params = OptParams(POMCPSolver, pomdp, 500, bu, 50)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        depth = Float64.(10:100)
    println("($i/$search_iter) \t c=$c \t depth=$depth")
    @show evaluate(params
        c = c,
        max_time=1.0,
        tree_queries=10_000_000,
        max_depth = Int(depth),
        default_action = (args...) -> rand(actions(pomdp))
    )
end

rmprocs(worker_ids)

save(join([@__DIR__,"/data/BasicPOMCP_params.jld2"]), Dict("ho"=>ho))
