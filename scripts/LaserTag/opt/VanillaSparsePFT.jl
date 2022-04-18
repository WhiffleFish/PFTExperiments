using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using Hyperopt
using FileIO, JLD2

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@info "Vanilla SparsePFT Discrete VDP Tag Hyperopt"
@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using LaserTag
    using PFTDPW
    using ParticleFilters
    using POMDPs
    using QMDP
end


const ITER = args["iter"]

params = COE.OptParams(
    SparsePFTSolver,
    gen_lasertag(),
    250,
    BootstrapFilter(gen_lasertag(), 10_000),
    20
)

qmdp = QMDPSolver()

ho = @hyperopt for i=ITER,
            sampler         = CLHSampler(
                                dims=[Continuous(), Continuous(), Continuous(),
                                      Continuous()]),
            _max_depth      = range(5,  50,  length=ITER),
            _k_o            = range(2,  30,  length=ITER),
            _c              = range(1,  100, length=ITER),
            _n_particles    = range(10, 500, length=ITER)

    println("$i / $ITER")
    COE.evaluate(
        params;
        action_selector = qmdp
        verbose = true,
        enable_action_pw = false,
        tree_queries = 100_000,
        max_time     = 0.1,
        max_depth    = round(Int,_max_depth),
        k_o          = _k_o,
        c            = _c,
        n_particles  = round(Int, _n_particles)
    )
end

path = joinpath(@__DIR__, "data", "VanillaSparsePFT.jld2")

Distributed.rmprocs(p)

FileIO.save(path, Dict("ho"=>ho))
