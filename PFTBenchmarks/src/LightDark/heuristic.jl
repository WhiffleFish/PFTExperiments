struct LightSteerSolver <: POMDPs.Solver end

struct LightSteer <: POMDPs.Policy end

POMDPs.solve(::LightSteerSolver, ::POMDP) = LightSteer()

function POMDPs.action(::LightSteer, b)
    s = mean(b)
    d = 10 - s

    v = if b isa ParticleCollection
        var(b.particles)
    else
        var(b)
    end

    if iszero(round(d)) && v < 3
        return -10
    elseif iszero(round(s)) && v < 2
        return 0
    elseif abs(d) > 5
        return Int(10*sign(d))
    else
        return Int(sign(d))
    end
end
