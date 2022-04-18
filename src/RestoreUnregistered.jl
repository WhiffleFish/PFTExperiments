using Pkg

try Pkg.rm("PFTDPW") catch end
try Pkg.rm("LaserTag") catch end
try Pkg.rm("SubHunt") catch end
try Pkg.rm("VDPTag2") catch end

Pkg.add(url="https://github.com/WhiffleFish/PFT-DPW.jl#main")
Pkg.add(url="https://github.com/JuliaPOMDP/LaserTag.jl#master")
Pkg.add(url="https://github.com/WhiffleFish/SubHunt.jl#master")
Pkg.add(url="https://github.com/WhiffleFish/VDPTag2.jl#master")
