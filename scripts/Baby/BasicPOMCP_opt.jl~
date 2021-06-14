using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")
@everywhere using BasicPOMCP

search_iter = 500

pomdp = BabyPOMDP()
bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(POMCPSolver, pomdp, 500, bu, 20)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        depth = Float64.(10:100)
    println("($i/$search_iter) \t c=$c \t depth=$depth")
    @show evaluate(params
        c = c,
        max_time=0.10,
        tree_queries=100_000,
        max_depth = Int(depth)
    )
end
rmprocs(worker_ids)

save(join([@__DIR__,"/data/BasicPOMCP_params.jld2"]), Dict("ho"=>ho))
