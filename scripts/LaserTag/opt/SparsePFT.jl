using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using Hyperopt
using FileIO, JLD2

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@info "SparsePFT LaserTag Hyperopt"
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

PO_VE = PFTDPW.PORollout(QMDPSolver(); n_rollouts=1)

const ITER = args["iter"]

params = COE.OptParams(
    PFTDPWSolver,
    pomdp,
    250,
    DiscreteUpdater(pomdp),
    20
)

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
        verbose = true,
        value_estimator = PO_VE,
        enable_action_pw = false,
        check_repeat_obs = false,
        tree_queries = 100_000,
        max_time     = 0.1,
        max_depth    = round(Int,_max_depth),
        k_o          = _k_o,
        alpha_o      = 0.0,
        c            = _c,
        n_particles  = round(Int, _n_particles)
    )
end

path = joinpath(@__DIR__, "data", "SparsePFT.jld2")

Distributed.rmprocs(p)

FileIO.save(path, Dict("ho"=>ho))
