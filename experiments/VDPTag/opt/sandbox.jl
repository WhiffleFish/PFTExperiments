using Hyperopt
using ContObsExperiments
const COE = ContObsExperiments
using Hyperopt

f(x,a,b=true;c=10) = sum(@. x + (a-3)^2 + (b ? 10 : 20) + (c-100)^2) # Function to minimize

# Main macro. The first argument to the for loop is always interpreted as the number of iterations (except for hyperband optimizer)
ho = @hyperopt for i=50,
            sampler = CLHSampler(dims=[Continuous(), Categorical(2), Continuous()]), # This is default if none provided
            a = LinRange(1,5,50),
            b = [true, false],
            c = exp10.(LinRange(-1,3,50))
   print(i, "\t", a, "\t", b, "\t", c, "   \t")
   x = 100
   @show f(x,a,b,c=c)
end

plot(ho)

##
using VDPTag2
using PFTDPW
using Distributed
using ParticleFilters
using POMDPs

@everywhere begin
    # using Pkg
    # Pkg.activate(".")
    using POMDPs
    using POMDPModels
    using BeliefUpdaters
    using ParticleFilters
    using POMDPSimulators
end

params = OptParams(
    SparsePFTSolver,
    VDPTagPOMDP(),
    10,
    BootstrapFilter(VDPTagPOMDP(), 10_000),
    20
)


ITER = 10
ho = @hyperopt for i=ITER,
            sampler         = CLHSampler(
                                dims=[Continuous(), Continuous(), Continuous(),
                                    Continuous(), Continuous()]),
            _max_depth      = LinRange(5,50,ITER),
            _k_o            = LinRange(2,30,ITER),
            _k_a            = LinRange(2,30,ITER),
            _c              = LinRange(1,100,ITER),
            _n_particles    = LinRange(10,500,ITER)

   evaluate(
        params;
        enable_action_pw = true,
        tree_queries = 100_000,
        max_time     = 0.1,
        max_depth    = round(Int,_max_depth),
        k_o          = _k_o,
        k_a          = _k_a,
        c            = _c,
        n_particles  = round(Int,_n_particles)
    )
end

plot(ho)
