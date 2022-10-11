struct ForgivingRolloutSimulator{RO<:Simulator} <: Simulator
    ro::RO
    max_tries::Int
    function ForgivingRolloutSimulator(max_tries=2; kwargs...)
        ro = RolloutSimulator(;kwargs...)
        return new{typeof(ro)}(ro, max_tries)
    end
end

function POMDPTools.Simulators.simulate(
    sim::ForgivingRolloutSimulator,
    pomdp::POMDP,
    policy::Policy,
    bu::Updater = updater(policy),
    b0 = initialstate(pomdp),
    s = rand(b0, sim.ro.rng)
    )

    local v̂::Float64
    for i ∈ 1:sim.max_tries
        try
            v̂ = simulate(sim.ro, pomdp, policy, bu, b0, s)
            break
        catch e
            if e isa ErrorException
                i < sim.max_tries ? @warn(e.msg) : throw(e)
            else
                throw(e)
            end
        end
    end
    return v̂
end
