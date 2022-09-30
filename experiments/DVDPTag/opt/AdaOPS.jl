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
    using VDPTag2
    using AdaOPS
    using ParticleFilters
    using POMDPs
    using POMDPPolicies
    using BasicPOMCP
    POMDPs.initialstate(p::ADiscreteVDPTagPOMDP) = initialstate(p.cpomdp)

    # AdaOPS calls observation(pomdp, a, sp) on setup just to get type of obs dist
    is = initialstate(ADiscreteVDPTagPOMDP())
    s = rand(is)
    a = rand(actions(ADiscreteVDPTagPOMDP()))
    sp = rand(is)
    POMDPs.observation(p::ADiscreteVDPTagPOMDP, a::Int, sp::TagState) = POMDPs.observation(p, s, a, sp)
end


const ITER = args["iter"]

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
        timeout_warning_threshold = Inf,
        T_max = 0.1,
        bounds = AdaOPS.IndependentBounds(
            BasicPOMCP.FORollout(RandomSolver()),
            1e6),
        m_min = round(Int,_m_min),
        delta = _δ
    )
end

path = joinpath(@__DIR__, "data", "AdaOPS.jld2")

Distributed.rmprocs(p)

FileIO.save(path, Dict("ho"=>ho))
