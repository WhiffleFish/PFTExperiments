using DelimitedFiles
using Plots

dvdp = convert(Matrix{Float64}, DelimitedFiles.readdlm("experiments/DVDPTag/ablate/data/SparsePFT.csv")[2:end,:])
lasertag = convert(Matrix{Float64}, DelimitedFiles.readdlm("experiments/LaserTag/ablate/data/SparsePFT.csv")[2:end,:])
lightdark = convert(Matrix{Float64}, DelimitedFiles.readdlm("experiments/LightDark/ablate/data/SparsePFT.csv")[2:end,:])
subhunt = convert(Matrix{Float64}, DelimitedFiles.readdlm("experiments/SubHunt/ablate/data/SparsePFT.csv")[2:end,:])
vdp = convert(Matrix{Float64}, DelimitedFiles.readdlm("experiments/VDPTag/ablate/data/SparsePFT.csv")[2:end,:])

function particle_ablation_plot(mat; σ=1,kwargs...)
    plot(mat[:,1], mat[:,2];
        # xscale=:log10,
        ribbon=mat[:,3]*σ,
        xminorticks=9,
        label="",
        xlabel = "Particle Count",
        ylabel = "Reward",
        kwargs...
    )
end

# pgfplotsx()

lasertag_plot = particle_ablation_plot(lasertag; title="Laser Tag", xscale=:log10, σ=2, xlabel="")
lightdark_plot = particle_ablation_plot(lightdark; title="Light Dark", xscale=:log10, σ=2 , xlabel="", ylabel="")
subhunt_plot = particle_ablation_plot(subhunt; title="Sub Hunt", xscale=:log10, σ=2, ylabel="")
vdp_plot = particle_ablation_plot(vdp; title="VDP Tag", xscale=:log10, σ=2)
dvdp_plot = particle_ablation_plot(dvdp; title="Discrete VDP Tag", xscale=:log10, σ=2, ylabel="")

p = plot(lasertag_plot, lightdark_plot, subhunt_plot, vdp_plot, dvdp_plot, layout=5)
savefig(p, "img/ablate/all_particle_sweeps.tex")
savefig(p, "img/ablate/all_particle_sweeps.svg")


savefig(dvdp_plot, "img/ablate/dvdp.tex")
savefig(lasertag_plot, "img/ablate/lasertag.tex")
savefig(lightdark_plot, "img/ablate/lightdark.tex")
savefig(subhunt_plot, "img/ablate/subhunt.tex")
savefig(vdp_plot, "img/ablate/vdp.tex")

## -----------------------------------------------------------------------------

using CairoMakie
using ColorSchemes
FONT = "Times New Roman"
FONTSIZE = 14
set_theme!(Theme(fontsize=FONTSIZE, font=FONT, titlefont="Time New Roman", titlecolor=:red))

size_inches = (8.3, 6.5)
size_pt = 72 .* size_inches
σ = 2
begin
    f = Figure(resolution = size_pt)#, fontsize = FONTSIZE)
    plot_particle_sweep!(f[1,1], lasertag, σ; title="Laser Tag", xlabel="")
    plot_particle_sweep!(f[1,2], lightdark, σ; title="Light Dark", xlabel="", ylabel="")
    plot_particle_sweep!(f[1,3], subhunt, σ; title="Sub Hunt", ylabel="")
    plot_particle_sweep!(f[2,1], vdp, σ; title="VDP Tag")
    plot_particle_sweep!(f[2,2], dvdp, σ; title="Discrete VDP Tag", ylabel="")
    f
end

save("img/ablate/all_particle_sweeps2.svg", f)
save("img/ablate/all_particle_sweeps2.pdf", f)

scheme = ColorSchemes.rainbow[range(0.0, 1.0, length=length(PFTPlots.SOLVER_LINESTYLES))]

function plot_particle_sweep!(f, data, σ; kwargs...)
    color = scheme[2]
    axis = Axis(
        f;
        xlabel              = "Particle Count",
        ylabel              = "Reward",
        xscale              = log10,
        xminorticksvisible  = true,
        xminorgridvisible   = true,
        xminorticks         = IntervalsBetween(9),
        titlefont="Time New Roman",
        kwargs...
    )
    lines!(data[:,1], data[:,2], color=color)
    band!(data[:,1], data[:,2] .- data[:,3] .* σ, data[:,2] .+ data[:,3] .* σ, color=(color,0.10))
end
