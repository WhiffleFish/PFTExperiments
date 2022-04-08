function LightDarkPlot(h::SimHistory)
    T = length(h)
    plot(0:(T-1),[t.s for t in h], label="", lw=5, xticks = 0:(T-1))
    scatter!(0:(T-1),[t.s for t in h], label="True State", ms=5)
    violin!(transpose((0:(T-1))), [t.b.particles for t in h], labels="", c="red", alpha=0.4)
    plot!(0:(T-1), zeros(T), ls=:dash, lc=:green, label="goal")
    xlabel!("Time Step")
    ylabel!("Position")
end
