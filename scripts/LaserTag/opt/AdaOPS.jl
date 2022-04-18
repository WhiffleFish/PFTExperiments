using ContObsExperiments
const COE = ContObsExperiments
using Distributed
using Hyperopt
using FileIO, JLD2

args = COE.parse_commandline()

p = addprocs(args["addprocs"]; exeflags="--project")

@info "AdaOPS Discrete VDP Tag Hyperopt"
@show length(procs())

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using LaserTag
    using AdaOPS
    using ParticleFilters
    using POMDPs
    using BasicPOMCP
end


const ITER = args["iter"]

params = COE.OptParams(
    SparsePFTSolver,
    gen_lasertag(),
    250,
    BootstrapFilter(gen_lasertag(), 10_000),
    20
)

ho = @hyperopt for i=ITER,
            sampler = CLHSampler(dims=[Continuous(), Continuous()]),
            _m_min  = range(10,  100,  length=ITER),
            _δ      = range(0.1, 1.0,  length=ITER)

    println("$i / $ITER")
    COE.evaluate(
        params;
        timeout_warning_threshold = Inf,
        T_max = 0.1,
        bounds = AdaOPS.IndependentBounds(
            BasicPOMCP.FORollout(RandomSolver()),
            AdaOPS.POValue(QMDPSolver()),
            check_terminal = true),
        m_min = _m_min,
        delta = _δ
    )
end

path = joinpath(@__DIR__, "data", "AdaOPS.jld2")

Distributed.rmprocs(p)

FileIO.save(path, Dict("ho"=>ho))
