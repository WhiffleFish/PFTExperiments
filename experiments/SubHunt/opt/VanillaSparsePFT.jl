using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using Hyperopt
using FileIO, JLD2

p = addprocs(19;exeflags="--project")

@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using SubHunt
    using PFTDPW
    using ParticleFilters
    using POMDPs
    using QMDP
end


const ITER = 100

params = COE.OptParams(
    SparsePFTSolver,
    SubHuntPOMDP(),
    250,
    BootstrapFilter(SubHuntPOMDP(), 100_000),
    20
)

qmdp = QMDPSolver()

ho = @hyperopt for i=ITER,
            sampler         = CLHSampler(
                                dims=[Continuous(), Continuous(), Continuous(),
                                      Continuous(), Continuous()]),
            _max_depth      = range(5,  50,  length=ITER),
            _k_o            = range(2,  30,  length=ITER),
            _c              = range(1,  100, length=ITER),
            _n_particles    = range(10, 500, length=ITER)

   COE.evaluate(
        params;
        verbose = true,
        enable_action_pw = false,
        action_selector = qmdp,
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
