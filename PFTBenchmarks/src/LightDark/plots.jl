function LightDarkPlot(h::SimHistory; pos_point::Bool=false, axis_labels::Bool=false)
    T = length(h)
    s_min, s_max = particle_lims(h)
    Y = s_min:1:s_max
    p = heatmap(
        0:(T-1),
        Y,
        lightmap(h;Y=Y),
        c=:greys,
        legend=:none
    )
    plot!(p,
        0:(T-1),
        [t.s for t in h],
        label="",
        lw=3,
        xticks = 0:(T-1),
        lc=:blue
    )
    pos_point && scatter!(p,
        0:(T-1),
        [t.s for t in h],
        label="True State",
        c = :orange,
        ms=5
    )
    violin!(p,
        transpose((0:(T-1))),
        [t.b.particles for t in h],
        labels="",
        c="red",
        alpha=0.4,
        bandwidth=.5,
        label = "Particle Belief"
    )
    plot!(p, 0:(T-1), zeros(T), ls=:dash, lc=:green, label="goal")
    if axis_labels
        xlabel!(p, "Time Step")
        ylabel!(p, "Position")
    end
    xlims!(0,T-1)
    ylims!(s_min, s_max)
    return p
end

function lightmap(h;Y=-30:30)
    T = length(h)
    d = abs.(10. .- Y)
    d ./= sum(d)
    m = Matrix{Float64}(undef, length(Y), T)
    for i in eachindex(Y)
        m[i,:] .= 1-d[i]
    end
    return m
end

function particle_lims(h)
    s_min = +Inf
    s_max = -Inf
    for t in h
        p = t.b.particles
        p_min, p_max = extrema(p)
        if p_max > s_max
            d,v = divrem(p_max, 10)
            s_max = d*10
            !iszero(v) && (s_max += 10)
        end
        if p_min < s_min
            d,v = divrem(p_min, 10)
            s_min = d*10
            !iszero(v) && (s_min -= 10)
        end
    end
    return s_min, s_max
end
