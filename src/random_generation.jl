random_point(rng::AbstractRNG = Random.default_rng()) = Point(
	rand(rng, 0:Int(2*MAX_23BIT_INT_I)) - MAX_23BIT_INT_I,
	rand(rng, 0:Int(2*MAX_23BIT_INT_I)) - MAX_23BIT_INT_I,
)

function random_noncrossing_segments(n::Integer, c::Color; rng::AbstractRNG = Random.default_rng())
	n < 0 && throw(ArgumentError("n must be nonnegative, got $n"))
	s= [Segment(random_point(rng), random_point(rng), c) for _ in 1:n]
    _untangle_segs!(s, c)
    return s
end

function _untangle_segs!(s::Vector{Segment}, c::Color)
	iterations = 0
	while true
		iterations += 1
		(iterations > 100_000) && break
		changed = false
		for i in 1:(length(s) - 1)
			for j in (i + 1):length(s)
				if intersect(s[i], s[j])
					pi, qi = s[i].p, s[i].q
					pj, qj = s[j].p, s[j].q
					s[i] = Segment(pi, qj, c)
					s[j] = Segment(pj, qi, c)
					changed = true
					break
				end
			end
			changed && break
		end
		changed || break
	end
	return s
end
	
function random_noncrossing_segments_rej(n::Integer, c::Color; rng::AbstractRNG = Random.default_rng())
    red_segments = Segment[]
	attempts = 0
	while length(red_segments) < n
		attempts += 1
		attempts <= 4n^2 || error("could not generate n non-intersecting c segments")
		candidate = Segment(random_point(rng), random_point(rng), c)
		all(s -> !RedBlueSegInt0.intersect(candidate, s), red_segments) || continue
		push!(red_segments, candidate)
    end
    return red_segments
end

function _random_distinct_points(n::Integer, rng::AbstractRNG)
	n < 0 && throw(ArgumentError("n must be nonnegative, got $n"))
	pts = Point[]
	seen = Set{Tuple{Int, Int}}()
	while length(pts) < n
		x = rand(rng, -MAX_23BIT_INT_I:MAX_23BIT_INT_I)
		y = rand(rng, -MAX_23BIT_INT_I:MAX_23BIT_INT_I)
		t = (x, y)
		if t in seen
			continue
		end
		push!(seen, t)
		push!(pts, Point(x, y))
	end
	return pts
end

function _edge_endpoints(points::Vector{Point}, i::Int, closed::Bool)
	n = length(points)
	a = points[i]
	b = (i == n) ? points[1] : points[i + 1]
	return a, b
end

function _edges_are_adjacent(i::Int, j::Int, m::Int, closed::Bool)
	(i == j) && return true
	(abs(i - j) == 1) && return true
	return closed && ((i == 1 && j == m) || (j == 1 && i == m))
end

function _untangle_points!(points::Vector{Point}, closed::Bool, c::Color)
	iterations = 0
	while true
		iterations += 1
		(iterations > 100_000) && break
		changed = false
		m = closed ? length(points) : (length(points) - 1)
		for i in 1:(m - 1)
			a, b = _edge_endpoints(points, i, closed)
			s = Segment(a, b, c)
			for j in (i + 1):m
				_edges_are_adjacent(i, j, m, closed) && continue
				cpt, dpt = _edge_endpoints(points, j, closed)
				t = Segment(cpt, dpt, c)
				if cross(s, t)
					reverse!(points, i + 1, j)
					changed = true
					break
				end
			end
			changed && break
		end
		changed || break
	end
	return points
end

function random_polyline(
	n::Integer,
	c::Color;
	closed::Bool = false,
	rng::AbstractRNG = Random.default_rng(),
)
	_check_color(c)
	if closed
		n < 3 && throw(ArgumentError("closed polygon needs at least 3 points, got $n"))
	else
		n < 2 && throw(ArgumentError("open polyline needs at least 2 points, got $n"))
	end
	points = _random_distinct_points(n, rng)
	_untangle_points!(points, closed, c)

	segments = Segment[]
	m = closed ? n : (n - 1)
	for i in 1:m
		p, q = _edge_endpoints(points, i, closed)
		push!(segments, Segment(p, q, c))
	end
	return segments
end
