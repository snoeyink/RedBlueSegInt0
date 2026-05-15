using CairoMakie, Random
using RedBlueSegInt0

function display_in_plotpane(fig)
	if isdefined(Main, :VSCodeServer)
		getproperty(getproperty(Main, :VSCodeServer), :vscodedisplay)(fig)
	else
		display(fig)
	end
	return fig
end

function plot_segments_and_crossings(red_segs::Vector{Segment}, blue_segs::Vector{Segment}; title_str="Red-Blue Segments")
	fig = Figure(size=(1200, 1000))
	ax = Axis(fig[1, 1], title=title_str, xlabel="X", ylabel="Y")

	# Plot red segments
	for seg in red_segs
		lines!(ax, [seg.p.x, seg.q.x], [seg.p.y, seg.q.y], color=:red, linewidth=2, alpha=0.7)
	end

	# Plot blue segments
	for seg in blue_segs
		lines!(ax, [seg.p.x, seg.q.x], [seg.p.y, seg.q.y], color=:blue, linewidth=2, alpha=0.7)
	end

	# Mark all segment endpoints
	for seg in red_segs
		scatter!(ax, [seg.p.x], [seg.p.y], color=:red, markersize=3, alpha=0.5)
		scatter!(ax, [seg.q.x], [seg.q.y], color=:red, markersize=3, alpha=0.5)
	end

	for seg in blue_segs
		scatter!(ax, [seg.p.x], [seg.p.y], color=:blue, markersize=3, alpha=0.5)
		scatter!(ax, [seg.q.x], [seg.q.y], color=:blue, markersize=3, alpha=0.5)
	end

	# Find and mark approximate intersection points
	cross_count = 0
	intersection_x = Float64[]
	intersection_y = Float64[]
	for r in red_segs
		for b in blue_segs
			if cross(r, b)
				cross_count += 1
				(approx_x, approx_y) = crossPt(Line2d(r), Line2d(b))
				push!(intersection_x, approx_x)
				push!(intersection_y, approx_y)
			end
		end
	end

	# Plot all intersections at once
	if !isempty(intersection_x)
		scatter!(ax, intersection_x, intersection_y, color=(:green, 0.6), markersize=8, 
			strokewidth=2, strokecolor=:green, label="Crossings ($cross_count)")
	end

	# Configure axes to avoid scientific notation
	ax.limits = (nothing, nothing, nothing, nothing)
	ax.xaxis.attributes[:scale] = identity
	ax.yaxis.attributes[:scale] = identity

	# legend!(ax, position=:rt)
	println("Total red-blue crossings: $cross_count")
	return fig, cross_count
end

# Generate example: 100 red segments and blue polyline of 100
function main()
	rng_red = MersenneTwister(2026)
	red_segments = random_noncrossing_segments_rej(100, :red; rng=rng_red)

	rng_blue = MersenneTwister(2027)
	blue_polyline = random_polyline(101, :blue; rng=rng_blue)

	crossing_count = 0
	for r in red_segments
		for b in blue_polyline
			if cross(r, b)
				crossing_count += 1
			end
		end
	end

	title_str = "100 Red Segments + Blue Polyline (100 edges): $crossing_count Crossings"
	fig, count = plot_segments_and_crossings(red_segments, blue_polyline, title_str=title_str)

	save("segments_plot.png", fig)
	display_in_plotpane(fig)
	println("Displayed plot in PlotPane when available")
	println("Plot saved to segments_plot.png")
	return fig, count
end

main()
