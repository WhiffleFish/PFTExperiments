using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using Hyperopt
using FileIO, JLD2

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@info "POMCPOW Discrete VDP Tag Hyperopt"
@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using LaserTag
    using POMCPOW
    using ParticleFilters
    using POMDPs
end


const ITER = args["iter"]

params = COE.OptParams(
    POMCPOWSolver,
    gen_lasertag(),
    250,
    BootstrapFilter(gen_lasertag(), 10_000),
    20
)

ho = @hyperopt for i=ITER,
            sampler         = CLHSampler(
                                dims=[Continuous(), Continuous(), Continuous(),
                                      Continuous()]),
            _max_depth      = range(5,  50,  length=ITER),
            _k_o            = range(2,  30,  length=ITER),
            _c              = range(1,  100, length=ITER),
            _α_o            = range(1e-2, 5e-1, length=ITER)

    println("$i / $ITER")
    COE.evaluate(
        params;
        verbose = true,
        enable_action_pw = false,
        check_repeat_obs = false,
        tree_queries = 100_000,
        max_time     = 0.1,
        max_depth    = round(Int,_max_depth),
        k_observation= _k_o,
        criterion    = MaxUCB(_c),
        alpha_observation  = round(Int, _α_o)
    )
end

path = joinpath(@__DIR__, "data", "POMCPOW.jld2")

Distributed.rmprocs(p)

FileIO.save(path, Dict("ho"=>ho))
