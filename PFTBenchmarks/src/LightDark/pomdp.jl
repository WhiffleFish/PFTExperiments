#=
The simple 1-D light dark problem from https://arxiv.org/pdf/1709.06196v6.pdf, section 5.2, or https://slides.com/zacharysunberg/defense-4#/39
=#
const R = 60
const LIGHT_LOC = 10

const LDPOMDP = QuickPOMDP(
    states = -R:R+1,                  # r+1 is a terminal state
    stateindex = s -> s + R + 1,
    actions = [-10, -1, 0, 1, 10],
    discount = 0.95,
    isterminal = s::Int -> s==R+1,
    obstype = Float64,

    transition = function (s::Int, a::Int)
        iszero(a) ? Deterministic(R+1) : Deterministic(clamp(s+a, -R, R))
    end,

    observation = (a, sp) -> Normal(sp, abs(sp - LIGHT_LOC) + 1e-3), # used to be (s,a,sp) but doesn't work with AdaOPS

    reward = function (s, a)
        if iszero(a)
            return iszero(s) ? 100.0 : -100.0
        else
            return -1.0
        end
    end,

    initialstate = POMDPTools.Uniform(div(-R,2):div(R,2))
)

LightDarkPOMDP() = LDPOMDP
