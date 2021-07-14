using Pkg
Pkg.rm("PFTDPW")
Pkg.rm("LaserTag")
Pkg.rm("SubHunt")
Pkg.rm("VDPTag2")

Pkg.add("https://github.com/WhiffleFish/PFT-DPW.jl#main")
Pkg.add("https://github.com/JuliaPOMDP/LaserTag.jl#master")
Pkg.add("https://github.com/WhiffleFish/SubHunt.jl#master")
Pkg.add("https://github.com/zsunberg/VDPTag2.jl#master")
