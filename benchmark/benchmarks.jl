using BenchmarkTools
using RedBlueSegInt0

const SUITE = BenchmarkGroup()
SUITE["sum_to_n_10000"] = @benchmarkable RedBlueSegInt0.sum_to_n(10_000)

results = run(SUITE)
display(results)
