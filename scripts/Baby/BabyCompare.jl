include("/Users/tyler/Documents/code/ContObsExperiments/src/benchmark.jl")
pomdp = BabyPOMDP()

t = 1.0
d = 20
k_obs = 1.0
k_act = 1.0
pft_solver = PFTDPWSolver(
    max_time=t,
    tree_queries=100_000,
    k_o=k_obs,
    alpha_o=0.0,
    k_a=k_act,
    max_depth=d,
    c=10.0,
    n_particles=100,
)
# pft_planner = solve(pomdp, pft_solver)

pomcpow_solver = POMCPOWSolver(
    max_time=t,
    tree_queries = 100_000,
    max_depth=d,
    criterion = MaxUCB(10.0),
    tree_in_info=false,
    k_observation = k_obs,
    alpha_observation = 0.0,
    k_action = k_act,
    enable_action_pw = false
)
# pomcpow_planner = solve(pomcpow_solver, pomdp)

solvers = Dict{Symbol, Solver}(:PFTDPW=>pft_solver, :POMCPOW=>pomcpow_solver)
max_steps = d
times = [0.01,0.05,0.1,0.5,1.0]
N = 100

BB = BatchBenchmark(pomdp, solvers, max_steps, N, times)
benchmark!(BB)

df = DataFrame(BB)

CSV.write("Baby_"*Dates.format(now(),"dd_mm_HH:MM:SS")*".csv", df)
