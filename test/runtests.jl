using Test
using Random
using RedBlueSegInt0
import RedBlueSegInt0: insert!, delete!, find_neighbors, reorder!

const RBVector2d = RedBlueSegInt0.Vector2d

@testset "RedBlueSegInt0" begin
	@testset "Point and Vector2d" begin
		p = Point(1, 2)
		q = Point(4, 6)
		v = q - p

		@test v == RBVector2d(3, 4)
		@test p + v == q
		@test q - v == p
		@test (5, 8) - p == RBVector2d(4, 6)
		@test p + (3, 4) == q

		u = RBVector2d(1, -2)
		@test u + v == RBVector2d(4, 2)
		@test v - u == RBVector2d(2, 6)
		@test perp(v) == RBVector2d(-4, 3)
		@test dot(v, v) == 25.0
	end

	@testset "Orientation" begin
		p = Point(0, 0)
		q = Point(2, 0)
		r_left = Point(1, 1)
		r_right = Point(1, -1)
		r_collinear = Point(3, 0)

		@test orient(p, q, r_left) > 0
		@test orient(p, q, r_right) < 0
		@test orient(p, q, r_collinear) == 0
		@test orient(p, q, r_left) == 2.0
	end

	@testset "Segment line equation" begin
		s = Segment(Point(0, 0), Point(2, 0), :red)
		n = line_normal(s)
		@test n == RBVector2d(0, 2)

		@test line_value(s, 1, 1) == 2.0
		@test line_value(s, 1, -1) == -2.0
		@test line_value(s, (1, 1)) == 2.0

		o = Point(1, 1)
		@test line_offset(s, o) == 2.0
		@test line_value(s, 1, 1, o) == line_value(s, 1, 1)
		@test line_value(s, 1, -1, o) == line_value(s, 1, -1)
		@test line_value(s, 2, 0, o) == line_value(s, 2, 0)
	end

	@testset "Segment ordering and crossing" begin
		s = Segment(Point(5, 0), Point(1, 0), :blue)
		@test s.p == Point(1, 0)
		@test s.q == Point(5, 0)
		@test s.reversed == true

		a = Segment(Point(0, 0), Point(2, 2), :red)
		b = Segment(Point(0, 2), Point(2, 0), :blue)
		c = Segment(Point(0, 0), Point(2, 0), :red)
		d = Segment(Point(1, 0), Point(3, 0), :blue)

		@test cross(a, b)
		@test RedBlueSegInt0.intersect(a, b)
		@test !cross(c, d)
		@test RedBlueSegInt0.intersect(c, d)
	end

	@testset "Flag sorting" begin
		earliest = Segment(Point(-1, 0), Point(0, 0), :blue)
		red_start = Segment(Point(0, 0), Point(2, 0), :red)
		blue_start = Segment(Point(0, 0), Point(1, 1), :blue)
		red_diag = Segment(Point(0, 0), Point(2, 2), :red)

		flags = sort_flags([red_start, blue_start, red_diag], [earliest])
		@test length(flags) == 8
		@test flags[1].segment == earliest && flags[1].start
		@test flags[2].segment == earliest && !flags[2].start
		@test flags[3].segment == red_diag && flags[3].start
		@test flags[4].segment == blue_start && flags[4].start
		@test flags[5].segment == red_start && flags[5].start

		overlap_a = Segment(Point(0, 0), Point(2, 2), :red)
		overlap_b = Segment(Point(0, 0), Point(3, 3), :red)
		@test_throws ArgumentError sort_flags([overlap_a, overlap_b], Segment[])
	end

	@testset "Active structure placeholders" begin
		s = SimpleVectorStructure()
		seg_a = Segment(Point(0, 0), Point(2, 0), :blue)
		seg_b = Segment(Point(0, 1), Point(2, 1), :blue)
		seg_c = Segment(Point(0, 2), Point(2, 2), :blue)

		insert!(s, seg_a, 0.0)
		insert!(s, seg_b, 0.0)
		insert!(s, seg_c, 0.0)
		@test length(s.segments) == 3

		above, below = find_neighbors(s, seg_b)
		@test above == seg_c
		@test below == seg_a

		delete!(s, seg_b, 1.0)
		@test length(s.segments) == 2
		@test find_neighbors(s, seg_b) == (nothing, nothing)

		@test reorder!(s, Point(1, 1)) === s
	end

	@testset "Random generators" begin
		rng1 = MersenneTwister(123)
		p = random_point(rng1)
		@test abs(p.x) <= MAX_23BIT_INT
		@test abs(p.y) <= MAX_23BIT_INT
		@test isinteger(p.x)
		@test isinteger(p.y)

		rng2 = MersenneTwister(456)
		segs = random_noncrossing_segments(100, :red; rng = rng2)
		@test length(segs) == 100
		@test all(s -> s.color == :red, segs)
		@test all(s -> (s.p.x < s.q.x) || (s.p.x == s.q.x && s.p.y <= s.q.y), segs)
		for i in 1:length(segs)-1
			for j in i+1:length(segs)
				@test !RedBlueSegInt0.intersect(segs[i], segs[j])
			end
		end

		crossing = [
			Segment(Point(0, 0), Point(2, 2), :red),
			Segment(Point(0, 2), Point(2, 0), :red),
		]
		RedBlueSegInt0._untangle_segs!(crossing, :red)
		@test !RedBlueSegInt0.intersect(crossing[1], crossing[2])
		@test Set([(s.p, s.q) for s in crossing]) ==
			Set([(Point(0, 0), Point(2, 0)), (Point(0, 2), Point(2, 2))])

		rng3 = MersenneTwister(789)
		open_chain = random_polyline(101, :blue; rng = rng3)
		@test length(open_chain) == 100
		for i in 1:length(open_chain)-1
			for j in i+1:length(open_chain)
				(abs(i - j) == 1) && continue
				@test !cross(open_chain[i], open_chain[j])
			end
		end

		rng4 = MersenneTwister(987)
		closed_chain = random_polyline(100, :red; closed = true, rng = rng4)
		@test length(closed_chain) == 100
		m = length(closed_chain)
		for i in 1:m-1
			for j in i+1:m
				(abs(i - j) == 1 || (i == 1 && j == m)) && continue
				@test !cross(closed_chain[i], closed_chain[j])
			end
		end
	end

end
