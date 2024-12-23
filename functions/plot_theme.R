library(ggplot2)

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
    
    legend.position="right",
    legend.direction="vertical",
    legend.title = element_text(colour="black", face="bold", size=12),
    legend.text = element_text(colour="black", size=10),
    
    plot.margin = margin(t = 5,  # Top margin
                         r = 5,  # Right margin
                         b = 5,  # Bottom margin
                         l = 5) # Left margin
  ) 