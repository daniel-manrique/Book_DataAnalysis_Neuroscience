library(ggplot2)

# Legend placement helpers. Book rule: put the legend inside an empty region of
# the panel when there is one; otherwise above or below the plot, laid out
# horizontally; use the right side (stacked vertically) only when neither fits.
# Add one of these after Plot_theme, e.g.  Plot_theme + legend_top()

# Inside the panel: x and y are fractions of the panel (0 to 1), where the
# legend's centre goes. Pick a corner that holds no data.
legend_inside <- function(x = 0.85, y = 0.85) {
  theme(
    legend.position = "inside",
    legend.position.inside = c(x, y),
    legend.direction = "vertical",
    legend.background = element_rect(fill = scales::alpha("white", 0.85), colour = NA),
    legend.key.height = unit(0.9, "lines")
  )
}

# Above the plot, one row, aligned with the left edge of the panel.
legend_top <- function() {
  theme(
    legend.position = "top",
    legend.direction = "horizontal",
    legend.justification = "left",
    legend.box.margin = margin(0, 0, -4, 0)
  )
}

# Below the plot, one row, centered.
legend_bottom <- function() {
  theme(legend.position = "bottom", legend.direction = "horizontal")
}

# At the right, stacked vertically (last resort: it narrows the panel).
legend_right <- function() {
  theme(legend.position = "right", legend.direction = "vertical")
}

# No legend (use when points are labelled directly or the axis already says it).
legend_none <- function() {
  theme(legend.position = "none")
}

# Default theme. Default legend sits above the plot, horizontal; override per
# figure with one of the helpers above. This object must stay the LAST
# expression in the file, because chapters read it with source(...)$value.
Plot_theme <- theme_classic() +
  theme(
    plot.title = element_text(size=18, hjust = 0.5, face="bold"),
    plot.subtitle = element_text(size = 14, color = "black", face="italic"),
    plot.caption = element_text(size = 12, color = "black"),
    plot.tag = element_text(size = 18),

    axis.line = element_line(colour = "black", linewidth = 1.5, linetype = "solid"),
    axis.ticks.length=unit(7,"pt"),

    axis.title.x = element_text(colour = "black", size = 16),
    axis.text.x = element_text(colour = "black", size = 16, angle = 0, hjust = 0.5),
    axis.ticks.x = element_line(colour = "black", linewidth = 1),

    axis.title.y = element_text(colour = "black", size = 16),
    axis.text.y = element_text(colour = "black", size = 16),
    axis.ticks.y = element_line(colour = "black", linewidth = 1),

    legend.position = "top",
    legend.direction = "horizontal",
    legend.justification = "left",
    legend.title = element_text(colour="black", face="bold", size=12),
    legend.text = element_text(colour="black", size=10),

    plot.margin = margin(t = 5,  # Top margin
                         r = 5,  # Right margin
                         b = 5,  # Bottom margin
                         l = 5) # Left margin
  )
