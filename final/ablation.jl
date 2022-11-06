using DelimitedFiles
using Plots

dvdp = DelimitedFiles.readdlm("experiments/DVDPTag/ablate/data/SparsePFT.csv")[2:end,:]
lasertag = DelimitedFiles.readdlm("experiments/LaserTag/ablate/data/SparsePFT.csv")[2:end,:]
lightdark = DelimitedFiles.readdlm("experiments/LightDark/ablate/data/SparsePFT.csv")[2:end,:]
subhunt = DelimitedFiles.readdlm("experiments/SubHunt/ablate/data/SparsePFT.csv")[2:end,:]
vdp = DelimitedFiles.readdlm("experiments/VDPTag/ablate/data/SparsePFT.csv")[2:end,:]

plot(dvdp[:,1], dvdp[:,2], ribbon=(dvdp[:,2] .- dvdp[:,3], dvdp[:,2] .+ dvdp[:,3]))
plot(lasertag[:,1], lasertag[:,2], ribbon=(lasertag[:,2] .- lasertag[:,3], lasertag[:,2] .+ lasertag[:,3]))
plot(lightdark[:,1], lightdark[:,2], ribbon=(lightdark[:,2] .- lightdark[:,3], lightdark[:,2] .+ lightdark[:,3]))
plot(subhunt[:,1], subhunt[:,2], ribbon=(subhunt[:,2] .- subhunt[:,3], subhunt[:,2] .+ subhunt[:,3]))
plot(vdp[:,1], vdp[:,2], ribbon=(vdp[:,2] .- vdp[:,3], vdp[:,2] .+ vdp[:,3]))


plot(dvdp[:,1], dvdp[:,2], ribbon=(dvdp[:,2] .- dvdp[:,3], dvdp[:,2] .+ dvdp[:,3]))
plot(lasertag[:,1], lasertag[:,2], ribbon=(lasertag[:,2] .- lasertag[:,3], lasertag[:,2] .+ lasertag[:,3]))
plot(lightdark[:,1], lightdark[:,2], ribbon=(lightdark[:,2] .- lightdark[:,3], lightdark[:,2] .+ lightdark[:,3]))
plot(subhunt[:,1], subhunt[:,2], ribbon=(subhunt[:,2] .- subhunt[:,3], subhunt[:,2] .+ subhunt[:,3]))
plot(vdp[:,1], vdp[:,2], ribbon=(first(vdp[:,2]) .- vdp[:,3],first(vdp[:,2]) .+ vdp[:,3]))


plot(vdp[:,1], vdp[:,2], xscale=:log10, ribbon=vdp[:,3], fillalpha=0.35)
plot!(vdp[:,1], vdp[:,2] .- vdp[:,3], c=:red)
# plot!(vdp[:,1], vdp[:,2] .+ vdp[:,3], c=:red)

#=
Run a lot fewer points but more simulations per point
- Only need to look at the diff between 1 and 10 - that's where we debug

- focus on lightdark first
    - if we only have 1 particle how could it possibly perform well
=#



particle_ablation_plot(dvdp; title="DVDPTag")
particle_ablation_plot(lasertag; title="LaserTag", xscale=:log10, σ=2)
particle_ablation_plot(lightdark; title="LightDark", xscale=:log10)
particle_ablation_plot(subhunt; title="SubHunt", xscale=:log10)
particle_ablation_plot(vdp; title="VDPTag", xscale=:log10)

function particle_ablation_plot(mat; σ=1,kwargs...)
    plot(mat[:,1], mat[:,2];
        # xscale=:log10,
        ribbon=mat[:,3]*σ,
        label="",
        xlabel = "Particle Count",
        ylabel = "Returns",
        kwargs...
    )
end
