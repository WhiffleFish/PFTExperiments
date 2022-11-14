@info "initializing experiments directory..."
println()

using Pkg
Pkg.activate(@__DIR__)

const BASE_DIR = abspath(joinpath(@__DIR__, ".."))

# alright, we're going scorched earth

try
    using ParticleFilterTrees
catch e
    if e isa ArgumentError || e isa LoadError
        try Pkg.rm("PFTBenchmarks") catch end
        try Pkg.rm("ParticleFilterTrees") catch end
        try Pkg.rm("LaserTag") catch end
        try Pkg.rm("SubHunt") catch end
        try Pkg.rm("VDPTag2") catch end
        Pkg.develop(path = joinpath(BASE_DIR, "PFTBenchmarks"))
        Pkg.add(url="https://github.com/WhiffleFish/ParticleFilterTrees.jl#main")
        Pkg.add(url="https://github.com/JuliaPOMDP/LaserTag.jl#master")
        Pkg.add(url="https://github.com/WhiffleFish/SubHunt.jl#master")
        Pkg.add(url="https://github.com/WhiffleFish/VDPTag2.jl.git#master")
    end
end

#=
try
    using PFTBenchmarks
    @info "✓ PFTBenchmarks"
catch e
    if e isa ArgumentError || e isa LoadError
        @info "PFTBenchmarks not found - installing"
        try Pkg.rm("PFTBenchmarks") catch end
        Pkg.develop(path = joinpath(BASE_DIR, "PFTBenchmarks"))
    end
end
println()

try
    using ParticleFilterTrees
    @info "✓ ParticleFilterTrees"
catch e
    if e isa ArgumentError || e isa LoadError
        @info "ParticleFilterTrees not found - installing"
        try Pkg.rm("ParticleFilterTrees") catch end
        Pkg.add(url="https://github.com/WhiffleFish/ParticleFilterTrees.jl#main")
    end
end
println()

try
    using LaserTag
    @info "✓ LaserTag"
catch e
    if e isa ArgumentError || e isa LoadError
        @info "LaserTag not found - installing"
        try Pkg.rm("LaserTag") catch end
        Pkg.add(url="https://github.com/JuliaPOMDP/LaserTag.jl#master")
    end
end
println()

try
    using SubHunt
    @info "✓ SubHunt"
catch e
    if e isa ArgumentError || e isa LoadError
        @info "SubHunt not found - installing"
        try Pkg.rm("SubHunt") catch end
        Pkg.add(url="https://github.com/WhiffleFish/SubHunt.jl#master")
    end
end
println()

try
    using VDPTag2
    @info "✓ VDPTag2"
catch e
    if e isa ArgumentError || e isa LoadError
        @info "VDPTag2 not found - installing"
        try Pkg.rm("VDPTag2") catch end
        Pkg.add(url="https://github.com/WhiffleFish/VDPTag2.jl.git#master")
    end
end
println()
=#
