using VDPTag2
using PFTDPW
using POMDPs
using ParticleFilters
using POMDPSimulators
using Plots
using Random
# pomdp = VDPTagPOMDP(mdp=VDPTagMDP(barriers=CardinalBarriers(0.2, 2.8)))
pomdp = VDPTagPOMDP()
sol = PFTDPWSolver(
    max_time            = 0.5,
    c                   = 70.,
    k_o                 = 8.0,
    k_a                 = 10.0,
    alpha_a             = 0.0,
    n_particles         = 20,
    max_depth           = 10,
    tree_queries        = 100_000,
    enable_action_pw    = true,
    check_repeat_obs    = false
)
planner = solve(sol, pomdp)

Random.seed!(1337)
hr = HistoryRecorder(max_steps = 20)
b0 = initialstate(pomdp)
hist = simulate(hr, pomdp, planner, BootstrapFilter(pomdp, 1_000))
plot(pomdp, hist)

getfield.(hist, :r)


## init

upscale = 1 #8x upscaling in resolution
fntsm = Plots.font("sans-serif", pointsize=round(10.0*upscale))
fntlg = Plots.font("sans-serif", pointsize=round(14.0*upscale))
default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
default(size=(800*upscale,600*upscale)) #Plot canvas size
default(xtickfont=font(pointsize=18),ytickfont=font(pointsize=18))#, legendfont=font(pointsize=18))

sh = state_hist(hist)
r = mdp(pomdp).tag_radius

xₜ(t,r,b) = r*cos(t) + b
yₜ(t,r,b) = r*sin(t) + b

p1 = begin
    idx = 1

    x_a, y_a = sh[idx].agent
    x_t, y_t = sh[idx].target

    plot(hist[idx].b, label="belief", ms=2, xaxis=nothing, yaxis=nothing)
    plot!(pomdp, legend=:bottomleft, legendfontsize=18)
    xlims!(-4,4)
    ylims!(-4,4)
    scatter!([x_a],[y_a], label="agent", color=:blue, markersize=10)
    scatter!([x_t],[y_t], label="target", color=:red, markersize=10)
    # plot!(t->xₜ(t,r,x_t), t->yₜ(t,r,y_t), 0, 2π, label="target", color=:red)
end

p2 = begin
    idx = 5

    x_a, y_a = sh[idx].agent
    x_t, y_t = sh[idx].target

    plot(pomdp, legend=:bottomleft, xaxis=nothing, yaxis=nothing)
    plot!(hist[idx].b, label="", ms=2)
    xlims!(-4,4)
    ylims!(-4,4)
    scatter!([x_a],[y_a], label="", color=:blue, markersize=10)
    scatter!([x_t],[y_t], label="", color=:red, markersize=10)
end

p3 = begin
    idx = 9

    x_a, y_a = sh[idx].agent
    x_t, y_t = sh[idx].target

    plot(pomdp, legend=:bottomleft, xaxis=nothing, yaxis=nothing)
    plot!(hist[idx].b, label="", ms=2)
    xlims!(-4,4)
    ylims!(-4,4)
    scatter!([x_a],[y_a], label="", color=:blue, markersize=10)
    scatter!([x_t],[y_t], label="", color=:red, markersize=10)
end

p4 = begin
    idx = 10

    x_a, y_a = sh[idx].agent
    x_t, y_t = sh[idx].target

    plot(pomdp, legend=:bottomleft, xaxis=nothing, yaxis=nothing)
    xlims!(-4,4)
    ylims!(-4,4)
    scatter!([x_a],[y_a], label="", color=:blue, markersize=10)
    scatter!([x_t],[y_t], label="", color=:red, markersize=10)
end

# plot(p1,p2,p3,p4, layout=grid(1,4, heights=[1.0,1.0,1.0,1.0]))

savefig(p1, "vdp_step1.pdf")
savefig(p2, "vdp_step5.pdf")
savefig(p3, "vdp_step9.pdf")
savefig(p4, "vdp_step10.pdf")
