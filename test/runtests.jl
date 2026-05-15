using Test
using RedBlueSegInt0

@testset "RedBlueSegInt0" begin
    @test isnothing(RedBlueSegInt0.greet())

    @test RedBlueSegInt0.sum_to_n(1) == 1
    @test RedBlueSegInt0.sum_to_n(10) == 55
end
