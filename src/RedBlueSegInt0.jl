module RedBlueSegInt0
using Random

export D, Color, RED, BLUE, MAX_23BIT_INT
export Point, Vector2d, Segment, Line2d
export Flag, sort_flags
export ActiveStructure, SimpleVectorStructure
export insert!, delete!, find_neighbors, reorder!
export perp, dot, orient, side, line_normal, line_offset, line_value
export cross, intersect, crossPt
export random_point, random_noncrossing_segments, random_noncrossing_segments_rej, random_polyline
export count_red_blue_crossings, crossPt

const D = true

const Color = Symbol
const RED::Color = :red
const BLUE::Color = :blue
const VALID_COLORS = (RED, BLUE)

# Keep coordinates in a range where integer products remain exact in Float64.
const MAX_23BIT_INT = 2.0^23 - 1.0
const MAX_23BIT_INT_I = Int(MAX_23BIT_INT)

function _check_coord_23bit_integer(v::Float64, name::Symbol)
	@static if D
		isfinite(v) || throw(ArgumentError("$name must be finite, got $v"))
		isinteger(v) || throw(ArgumentError("$name must be an integer-valued Float64, got $v"))
		abs(v) <= MAX_23BIT_INT ||
			throw(ArgumentError("$name must satisfy |$name| <= $(MAX_23BIT_INT_I), got $v"))
	end
	return v
end

function _check_color(c::Color)
	@static if D
		c in VALID_COLORS || throw(ArgumentError("color must be :red or :blue, got $c"))
	end
	return c
end

struct Point
	x::Float64
	y::Float64

	function Point(x::Real, y::Real)
		xf = _check_coord_23bit_integer(Float64(x), :x)
		yf = _check_coord_23bit_integer(Float64(y), :y)
		return new(xf, yf)
	end
end

Point(t::NTuple{2,<:Real}) = Point(t[1], t[2])

_point_leq(p::Point, q::Point) = (p.x < q.x) || (p.x == q.x && p.y <= q.y)

struct Vector2d
	x::Float64
	y::Float64

	Vector2d(x::Real, y::Real) = new(Float64(x), Float64(y))
end

Vector2d(t::NTuple{2,<:Real}) = Vector2d(t[1], t[2])

struct Segment
	p::Point
	q::Point
	color::Color
	reversed::Bool

	function Segment(p::Point, q::Point, color::Color, reversed::Bool = false)
		c = _check_color(color)
		if _point_leq(p, q)
			return new(p, q, c, reversed)
		end
		return new(q, p, c, !reversed)
	end
end

Segment(px::Real, py::Real, qx::Real, qy::Real, color::Color, reversed::Bool = false) =
	Segment(Point(px, py), Point(qx, qy), color, reversed)

Base.:-(p::Point, q::Point) = Vector2d(p.x - q.x, p.y - q.y)
Base.:+(p::Point, v::Vector2d) = Point(p.x + v.x, p.y + v.y)
Base.:-(p::Point, v::Vector2d) = Point(p.x - v.x, p.y - v.y)
Base.:+(u::Vector2d, v::Vector2d) = Vector2d(u.x + v.x, u.y + v.y)
Base.:-(u::Vector2d, v::Vector2d) = Vector2d(u.x - v.x, u.y - v.y)
Base.:-(pxy::NTuple{2,<:Real}, p::Point) = Point(pxy) - p
Base.:+(p::Point, vxy::NTuple{2,<:Real}) = p + Vector2d(vxy)
Base.:(==)(p::Point, q::Point) = p.x == q.x && p.y == q.y
Base.:(==)(u::Vector2d, v::Vector2d) = u.x == v.x && u.y == v.y

perp(v::Vector2d) = Vector2d(-v.y, v.x)
dot(u::Vector2d, v::Vector2d) = muladd(u.x, v.x, u.y * v.y)

orient(p::Point, q::Point, r::Point) = dot(perp(q - p), r - p)

const ORIGIN_POINT = Point(0, 0)

line_normal(s::Segment) = perp(s.q - s.p)
line_offset(s::Segment, o::Point = ORIGIN_POINT) = dot(perp(s.p - o), s.q - o)

side(s::Segment, r::Point) = dot(line_normal(s), r - s.p)
side(s::Segment, x::Real, y::Real) = side(s, Point(x, y))
side(s::Segment, xy::NTuple{2,<:Real}) = side(s, Point(xy))

line_value(s::Segment, r::Point) = side(s, r)
line_value(s::Segment, x::Real, y::Real) = side(s, x, y)
line_value(s::Segment, xy::NTuple{2,<:Real}) = side(s, xy)
line_value(s::Segment, r::Point, o::Point) = line_offset(s, o) + dot(line_normal(s), r - o)
line_value(s::Segment, x::Real, y::Real, o::Point) = line_value(s, Point(x, y), o)
line_value(s::Segment, xy::NTuple{2,<:Real}, o::Point) = line_value(s, Point(xy), o)

cross(s::Segment, t::Segment) =
	(sign(side(s, t.p)) * side(s, t.q) < 0) &&
	(sign(side(t, s.p)) * side(t, s.q) < 0)

intersect(s::Segment, t::Segment) =
	(sign(side(s, t.p)) * side(s, t.q) <= 0) &&
	(sign(side(t, s.p)) * side(t, s.q) <= 0)

struct Line2d
	w::Float64
	n::Vector2d
end

struct Flag
	segment::Segment
	start::Bool
end

abstract type ActiveStructure end

struct SimpleVectorStructure <: ActiveStructure
	segments::Vector{Segment}
end

SimpleVectorStructure() = SimpleVectorStructure(Segment[])

function insert!(structure::ActiveStructure, segment::Segment, x_coord::Real)
	throw(MethodError(insert!, (structure, segment, x_coord)))
end

function delete!(structure::ActiveStructure, segment::Segment, x_coord::Real)
	throw(MethodError(delete!, (structure, segment, x_coord)))
end

function find_neighbors(structure::ActiveStructure, segment::Segment)
	throw(MethodError(find_neighbors, (structure, segment)))
end

function reorder!(structure::ActiveStructure, event_point::Point)
	throw(MethodError(reorder!, (structure, event_point)))
end

function insert!(structure::SimpleVectorStructure, segment::Segment, x_coord::Real)
	push!(structure.segments, segment)
	return structure
end

function delete!(structure::SimpleVectorStructure, segment::Segment, x_coord::Real)
	idx = findfirst(==(segment), structure.segments)
	idx === nothing || deleteat!(structure.segments, idx)
	return structure
end

function find_neighbors(structure::SimpleVectorStructure, segment::Segment)
	idx = findfirst(==(segment), structure.segments)
	idx === nothing && return (nothing, nothing)
	above = idx < length(structure.segments) ? structure.segments[idx + 1] : nothing
	below = idx > 1 ? structure.segments[idx - 1] : nothing
	return (above, below)
end

function reorder!(structure::SimpleVectorStructure, event_point::Point)
	# Placeholder for future event-local reordering logic.
	return structure
end

flag_point(flag::Flag) = flag.start ? flag.segment.p : flag.segment.q
flag_type_rank(flag::Flag) = flag.start ? 1 : 0

function _segment_slope_cmp(a::Segment, b::Segment)
	da = a.q - a.p
	db = b.q - b.p
	da.x == 0 && db.x == 0 && return 0
	da.x == 0 && return 1
	db.x == 0 && return -1
	lhs = da.y * db.x
	rhs = db.y * da.x
	lhs < rhs && return -1
	lhs > rhs && return 1
	return 0
end

function _flag_slope_cmp(a::Flag, b::Flag)
	cmp = _segment_slope_cmp(a.segment, b.segment)
	return a.start ? -cmp : cmp
end

function _flag_color_rank(flag::Flag)
	return flag.start ? (flag.segment.color == RED ? 0 : 1) : (flag.segment.color == BLUE ? 0 : 1)
end

function _flag_isless(a::Flag, b::Flag)
	pa = flag_point(a)
	pb = flag_point(b)
	pa.x < pb.x && return true
	pa.x > pb.x && return false
	pa.y < pb.y && return true
	pa.y > pb.y && return false

	flag_type_rank(a) < flag_type_rank(b) && return true
	flag_type_rank(a) > flag_type_rank(b) && return false

	cmp = _flag_slope_cmp(a, b)
	cmp < 0 && return true
	cmp > 0 && return false

	ra = _flag_color_rank(a)
	rb = _flag_color_rank(b)
	ra < rb && return true
	ra > rb && return false

	return false
end

function _check_for_overlapping_same_color(flags::Vector{Flag})
	for i in 2:length(flags)
		prev = flags[i - 1]
		curr = flags[i]
		(flag_point(prev) == flag_point(curr) &&
		 flag_type_rank(prev) == flag_type_rank(curr) &&
		 _flag_slope_cmp(prev, curr) == 0 &&
		 prev.segment.color == curr.segment.color) || continue
		throw(ArgumentError("overlapping segments of the same color are not allowed"))
	end
	return flags
end

function sort_flags(r::Vector{Segment}, b::Vector{Segment})
	flags = Flag[]
	append!(flags, Flag(seg, true) for seg in r)
	append!(flags, Flag(seg, false) for seg in r)
	append!(flags, Flag(seg, true) for seg in b)
	append!(flags, Flag(seg, false) for seg in b)
	sort!(flags, lt = _flag_isless)
	return _check_for_overlapping_same_color(flags)
end

Line2d(s::Segment) = Line2d(line_offset(s), line_normal(s))

side(l::Line2d, p::Point) = l.w + dot(l.n, p)

function crossPt(l::Line2d, m::Line2d)
	den = dot(perp(l.n), m.n)
	# if abs(den) < 1e-12
	if den==0 # exact check since all coordinates are integers in a small range
        error("Should only call crossPt for crossing segments, but lines are parallel")
	end
	numer_x = muladd(-l.w, m.n.y,  l.n.y * m.w)
	numer_y = muladd( l.w, m.n.x, -l.n.x * m.w)
	return (numer_x / den, numer_y / den)
end

function count_red_blue_crossings(red_segs::Vector{Segment}, blue_segs::Vector{Segment})::Int
	count = 0
	for r in red_segs
		for b in blue_segs
			if cross(r, b)
				count += 1
			end
		end
	end
	return count
end

include("random_generation.jl")


end # module RedBlueSegInt0
