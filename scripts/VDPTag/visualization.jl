using CairoMakie
set_theme!(Theme(fontsize=19, font="Times New Roman"))

function vdp(x,y,μ=2.)
    ẋ = μ*(x - (x^3 / 3) - y)
    ẏ = x / μ
    return (ẋ, ẏ)
end

X = -5:0.5:5
Y = -5:0.5:5
dx = [vdp(x,y,.5) for x in X, y in Y]
u = first.(dx)
v = last.(dx)

p = arrows(
    X, Y, u, v,
    arrowsize=7,
    lengthscale=0.05,
    color=(:blue, 0.90),
    linewidth=2,
    # axis=(;title="Van Der Pol Vector Field (μ=0.5)")
)


save(joinpath(COE.PROJECT_ROOT, "img", "vdp_vectorfield_notitle.pdf"), p)
