using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using Hyperopt
using FileIO, JLD2

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@info "Vanilla SparsePFT LaserTag Hyperopt"
@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using LaserTag
    using PFTDPW
    using ParticleFilters
    using BeliefUpdaters
    using POMDPs
    using QMDP
    const pomdp = gen_lasertag()
    import Distributions
    Distributions.support(::LaserTag.LTInitialBelief) = states(pomdp)
end


const ITER = args["iter"]

params = COE.OptParams(
    SparsePFTSolver,
    pomdp,
    250,
    DiscreteUpdater(pomdp),
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
    @show _max_depth _k_o _c _n_particles
    COE.evaluate(
        params;
        action_selector = qmdp,
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
