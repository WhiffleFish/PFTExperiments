using Distributed

worker_ids = addprocs(20; exeflags="--project")

include("../../src/evaluate.jl")

@everywhere begin
    using QuickPOMDPs
    using POMDPModelTools
    using Distributions
    using PFTDPW

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

k_a = length(actions(pomdp)) - 1

bu = BootstrapFilter(pomdp, 1_000)
params = OptParams(PFTDPWSolver, pomdp, 500, bu, 40)

ho = @hyperopt for i=search_iter,
        sampler = GPSampler(Max),
        c = Float64.(1:100),
        k_obs = Float64.(1:20),
        k_act = Float64.(2:10),
        max_depth = Float64.(10:100),
        n_p = Float64.([10,20,50,100,500,1_000])
    println("($i/$search_iter) \t c=$c \t k_obs=$k_obs \t k_act=$k_act \t n_p=$n_p")
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
save("scripts/LightDark/data/SparsePFT_params.jld2", Dict("ho"=>ho))
