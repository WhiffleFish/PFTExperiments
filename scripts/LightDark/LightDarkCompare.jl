include(join([@__DIR__,"/pomdp.jl"]))
pomdp = LightDarkPOMDP

t = 1.0
d = 50
pft_solver = PFTDPWSolver(
    max_time=t,
    tree_queries=100_000,
    k_o=10.0,
    alpha_o=0.5,
    k_a=2,
    max_depth=d,
    c=10.0,
    n_particles=100,
)

pft_planner = solve(pomdp, pft_solver)

pomcpow_solver = POMCPOWSolver(
    max_time=t,
    tree_queries = 100_000,
    max_depth=d,
    criterion = MaxUCB(10.0),
    tree_in_info=false,
    enable_action_pw = false
)
pomcpow_planner = solve(pomcpow_solver, pomdp)

policies = Dict{Symbol, Policy}(:PFTDPW=>pft_planner, :POMCPOW=>pomcpow_planner)
max_steps = d
times = [0.01,0.05,0.1,0.5,1.0]
N = 100

BB = BatchBenchmark(pomdp, policies, max_steps, N, times)
benchmark!(BB)
