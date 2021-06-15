using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")

@everywhere begin
    using QuickPOMDPs
    using POMDPModelTools
    using Distributions
    using BasicPOMCP

    r = 60
    light_loc = 10

    pomdp = QuickPOMDP(
        states = -r:r+1, # r+1 is terminal
        actions = [-10, -1, 0, 1, 10],
        discount = 0.95,
        isterminal = s -> !(s in -r:r),
        obstype = Float64,

        transition = function (s, a)
            if a == 0
                return Deterministic(r+1)
            else
                return Deterministic(clamp(s+a, -r, r))
            end
        end,

        observation = (s, a, sp) -> Normal(sp, abs(sp - light_loc) + 0.0001),

        reward = function (s, a, sp, o)
            if a == 0
                return s == 0 ? 100 : -100
            else
                return -1.0
            end
        end,

        initialstate = POMDPModelTools.Uniform(div(-r,2):div(r,2))
    )
end

search_iter = 200

bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(POMCPSolver, pomdp, 500, bu, 40)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        depth = Float64.(10:100)
    println("($i/$search_iter) \t c=$c \t depth=$depth")
    @show evaluate(params;
        c = c,
        max_time=0.10,
        tree_queries=100_000,
        max_depth = Int(depth),
        default_action = (args...) -> rand(actions(pomdp))
    )
end

rmprocs(worker_ids)

save(join([@__DIR__,"/data/BasicPOMCP_params.jld2"]), Dict("ho"=>ho))