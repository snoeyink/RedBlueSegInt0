using BenchmarkTools
using RedBlueSegInt0

const SUITE = BenchmarkGroup()


results = run(SUITE)
display(results)
