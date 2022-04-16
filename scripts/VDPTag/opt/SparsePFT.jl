using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using Hyperopt
using FileIO, JLD2

p = addprocs(19)

@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using VDPTag2
    using PFTDPW
    using ParticleFilters
    using POMDPs
end


const ITER = 100

params = COE.OptParams(
    SparsePFTSolver,
    VDPTagPOMDP(),
    250,
    BootstrapFilter(VDPTagPOMDP(), 10_000),
    20
)


ho = @hyperopt for i=ITER,
            sampler         = CLHSampler(
                                dims=[Continuous(), Continuous(), Continuous(),
                                      Continuous(), Continuous()]),
            _max_depth      = LinRange(5,  50,  ITER),
            _k_o            = LinRange(2,  30,  ITER),
            _k_a            = LinRange(2,  30,  ITER),
            _c              = LinRange(1,  100, ITER),
            _n_particles    = LinRange(10, 500, ITER)

   COE.evaluate(
        params;
        verbose = true,
        enable_action_pw = true,
        tree_queries = 100_000,
        max_time     = 0.1,
        max_depth    = round(Int,_max_depth),
        k_o          = _k_o,
        k_a          = _k_a,
        c            = _c,
        n_particles  = round(Int, _n_particles)
    )
end

path = joinpath(@__DIR__, "data", "SparsePFT.jld2")

Distributed.rmprocs(p)

FileIO.save(path, Dict("ho"=>ho))
