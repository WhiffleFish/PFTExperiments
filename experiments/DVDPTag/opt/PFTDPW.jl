using PFTBenchmarks
const COE = PFTBenchmarks
using Distributed
using Hyperopt
using FileIO, JLD2

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@info "PFTDPW Discrete VDP Tag Hyperopt"
@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using PFTBenchmarks
    using VDPTag2
    using ParticleFilterTrees
    const PFT = ParticleFilterTrees
    using ParticleFilters
    using POMDPs
    const pomdp = ADiscreteVDPTagPOMDP(cpomdp=VDPTagPOMDP(mdp=VDPTagMDP(barriers=CardinalBarriers(0.2, 2.8))), n_angles=20)
end

const ITER = args["iter"]

params = COE.OptParams(
    PFTDPWSolver,
    pomdp,
    args["test"] ? 5 : 250,
    BootstrapFilter(pomdp, 100_000),
    20
)

ho = @hyperopt for i=ITER,
            sampler         = CLHSampler(
                                dims=[Continuous(), Continuous(), Continuous(),
                                      Continuous(), Continuous(), Continuous()]),
            _max_depth      = range(5,   50,    length=ITER),
            _k_o            = range(2,   30,    length=ITER),
            _α_o            = range(-2,  0,     length=ITER) .|> exp10,
            _c              = range(1,   100,   length=ITER),
            _inv_β          = range(1,  16,     length=ITER),
            _n_particles    = range(10,  500,   length=ITER)

    println("$i / $ITER")
    COE.evaluate(
        params;
        verbose = true,
        enable_action_pw = false,
        check_repeat_obs = false,
        tree_queries = 100_000,
        max_time     = 0.1,
        max_depth    = round(Int,_max_depth),
        k_o          = _k_o,
        alpha_o      = _α_o,
        criterion    = PFT.MaxPoly(_c,inv(_inv_β)),
        n_particles  = round(Int, _n_particles)
    )
end

path = joinpath(@__DIR__, "data", "PFTDPW.jld2")

Distributed.rmprocs(p)

FileIO.save(path, Dict("ho"=>ho))
