using SARSOP
using POMDPModels

pomdp = BabyPOMDP()
solver = SARSOPSolver(timeout=60.0^2)
policy = solve(solver, pomdp)
