@info "initializing experiments directory..."
println()

using Pkg
Pkg.activate(@__DIR__)

try
    using PFTBenchmarks
    @info "✓ PFTBenchmarks"
catch e
    if e isa ArgumentError || e isa LoadError
        @info "PFTBenchmarks not found - installing"
        try Pkg.rm("PFTBenchmarks") catch end
        Pkg.develop(path = joinpath(@__DIR__, "PFTBenchmarks"))
    end
end

try
    using PFTPlots
    @info "✓ PFTPlots"
catch e
    if e isa ArgumentError || e isa LoadError
        @info "PFTPlots not found - installing"
        try Pkg.rm("PFTPlots") catch end
        Pkg.develop(path = joinpath(@__DIR__, "PFTPlots"))
    end
end

include(joinpath(@__DIR__, "experiments", "init.jl"))
