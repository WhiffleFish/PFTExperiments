using Pkg

Pkg.active(@__DIR__)
Pkg.update()

Pkg.activate(joinpath(@__DIR__, "PFTPlots"))
Pkg.update()

Pkg.activate(joinpath(@__DIR__, "PFTBenchmarks"))
Pkg.update()

Pkg.activate(joinpath(@__DIR__, "experiments"))
Pkg.update()
