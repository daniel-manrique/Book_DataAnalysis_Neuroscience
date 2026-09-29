# Simulated electrophysiology dataset: spontaneous spike counts after a treatment
#
# 150 single units (75 control, 75 treated), one row per unit. Each unit was
# recorded for a different length of time (`duration_s`, 20-120 s: the recording
# is cut when the unit stops being stable), so the raw spike count mixes "how
# fast does this cell fire" with "how long did we listen" -> the offset problem.
#
# Two mechanisms generate the data, on purpose, so the book can say what the
# truth was:
#   1. A fraction of units is silent in this window (structural zeros; think of
#      units identified in an earlier evoked session that do not fire
#      spontaneously here). The
#      treatment silences more of them (35% vs 20%).
#   2. Active units fire at a rate that varies from unit to unit (Gamma
#      heterogeneity, shape = 2), which is exactly a negative binomial count.
#      The treatment multiplies the active units' rate by 0.6.
#
# Units are one row each and treated as independent in ch. 3.7. In real
# recordings they are nested in animals; that is the point of ch. 4.3.
#
# Output: project/AnalysisData/Ephys_spikes_simulated.csv  -> ch. 3.7
# Run from the project root: source("functions/simulate_ephys.R")

set.seed(2027)

n_units <- 150

units <- data.frame(
  unit       = sprintf("U%03d", seq_len(n_units)),
  group      = rep(c("control", "treated"), each = n_units / 2),
  duration_s = round(runif(n_units, 20, 120))
)

# True parameters (kept here so the book can say what the generative process was)
rate_control  <- 0.25   # spikes/s of an active control unit (median cortical-ish)
rate_ratio    <- 0.6    # treated / control, active units
p_silent_ctrl <- 0.20   # probability of a structurally silent unit, control
p_silent_trt  <- 0.35   # ... treated
phi           <- 2      # negative binomial shape (Gamma heterogeneity)

treated <- units$group == "treated"
units$silent <- rbinom(n_units, 1, ifelse(treated, p_silent_trt, p_silent_ctrl))
mu <- units$duration_s * rate_control * ifelse(treated, rate_ratio, 1)
units$spikes <- ifelse(units$silent == 1, 0L, rnbinom(n_units, mu = mu, size = phi))

# `silent` is the hidden truth: the book never gives it to the model
out <- units[, c("unit", "group", "duration_s", "spikes")]
dir.create("project/AnalysisData", showWarnings = FALSE, recursive = TRUE)
write.csv(out, "project/AnalysisData/Ephys_spikes_simulated.csv", row.names = FALSE)
