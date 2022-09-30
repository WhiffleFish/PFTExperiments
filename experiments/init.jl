@info "initializing experiments directory..."
println()

using Pkg
Pkg.activate(@__DIR__)

const BASE_DIR = abspath(joinpath(@__DIR__, ".."))

try
    using PFTBenchmarks
    @info "✓ PFTBenchmarks"
catch ArgumentError
    @info "PFTBenchmarks not found - installing"
    try Pkg.rm("PFTBenchmarks") catch end
    Pkg.develop(path = joinpath(BASE_DIR, "PFTBenchmarks"))
end
println()


try
    using ParticleFilterTrees
    @info "✓ ParticleFilterTrees"
catch ArgumentError
    @info "ParticleFilterTrees not found - installing"
    try Pkg.rm("ParticleFilterTrees") catch end
    Pkg.add(url="https://github.com/WhiffleFish/ParticleFilterTrees.jl#main")
end
println()

try
    using LaserTag
    @info "✓ LaserTag"
catch ArgumentError
    @info "LaserTag not found - installing"
    try Pkg.rm("LaserTag") catch end
    Pkg.add(url="https://github.com/JuliaPOMDP/LaserTag.jl#master")
end
println()



try
    using SubHunt
    @info "✓ SubHunt"
catch ArgumentError
    @info "SubHunt not found - installing"
    try Pkg.rm("SubHunt") catch end
    Pkg.add(url="https://github.com/WhiffleFish/SubHunt.jl#master")
end
println()

try
    using VDPTag2
    @info "✓ VDPTag2"
catch ArgumentError
    @info "VDPTag2 not found - installing"
    try Pkg.rm("VDPTag2") catch end
    Pkg.add(url="https://github.com/WhiffleFish/SubHunt.jl#master")
end
println()
