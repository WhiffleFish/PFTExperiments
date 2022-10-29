@info "initializing experiments directory..."
println()

using Pkg
Pkg.activate(@__DIR__)

try
    using PFTBenchmarks
    @info "✓ PFTBenchmarks"
catch ArgumentError
    @info "PFTBenchmarks not found - installing"
    try Pkg.rm("PFTBenchmarks") catch end
    Pkg.develop(path = joinpath(@__DIR__, "PFTBenchmarks"))
end

try
    using PFTPlots
    @info "✓ PFTPlots"
catch ArgumentError
    @info "PFTPlots not found - installing"
    try Pkg.rm("PFTPlots") catch end
    Pkg.develop(path = joinpath(@__DIR__, "PFTPlots"))
end
