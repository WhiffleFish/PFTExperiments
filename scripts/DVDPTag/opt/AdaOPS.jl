using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using Hyperopt
using FileIO, JLD2

p = addprocs(39;exeflags="--project")

@info "AdaOPS Discrete VDP Tag Hyperopt"
@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using VDPTag2
    using AdaOPS
    using ParticleFilters
    using POMDPs
    using BasicPOMCP
end


const ITER = 100

params = COE.OptParams(
    AdaOPSSolver,
    ADiscreteVDPTagPOMDP(n_angles=20),
    250,
    BootstrapFilter(ADiscreteVDPTagPOMDP(n_angles=20), 10_000),
    20
)

ho = @hyperopt for i=ITER,
            sampler = CLHSampler(dims=[Continuous(), Continuous()]),
            _m_min  = range(10,  100,  length=ITER),
            _δ      = range(0.1, 1.0,  length=ITER)

    println("$i / $ITER")
    COE.evaluate(
        params;
        bounds = AdaOPS.IndependentBounds(
            BasicPOMCP.FORollout(RandomSolver()),
            1e6),
        m_min = _m_min,
        delta = _δ
    )
end

path = joinpath(@__DIR__, "data", "AdaOPS.jld2")

Distributed.rmprocs(p)

FileIO.save(path, Dict("ho"=>ho))
