# Simulated behavioral dataset: memory-probe task after a treatment
#
# 60 mice (30 vehicle, 30 treated), ages 8-30 weeks. Each mouse runs 10 training
# trials (correct / incorrect) and one final probe (passed / not passed).
# Every mouse has its own baseline ability (u_i ~ Normal(0, 0.8) on the logit
# scale), which is what makes trials from the same mouse non-independent.
#
# Two files are written to project/AnalysisData/:
#   Behavior_simulated.csv         one row per mouse (probe outcome)  -> ch. 3.6
#   Behavior_trials_simulated.csv  one row per trial                  -> ch. 3.8, 4.3
#
# Run from the project root: source("functions/simulate_behavior.R")

set.seed(2026)

n_mice <- 60
mice <- data.frame(
  mouse     = sprintf("M%02d", seq_len(n_mice)),
  group     = rep(c("vehicle", "treated"), each = n_mice / 2),
  age_weeks = round(runif(n_mice, 8, 30))
)

# True parameters on the logit scale (kept here so the book can say what the
# generative process was; the chapter never asks the reader to trust them)
beta0     <- -0.3   # vehicle mouse of 19 weeks
beta_trt  <-  1.2   # treatment
beta_age  <- -0.07  # per week, centered at 19 weeks
sd_mouse  <-  0.8

mice$u   <- rnorm(n_mice, 0, sd_mouse)
mice$eta <- beta0 + beta_trt * (mice$group == "treated") +
  beta_age * (mice$age_weeks - 19) + mice$u

# One probe per mouse
mice$passed_probe <- rbinom(n_mice, 1, plogis(mice$eta))

trials <- merge(
  mice[, c("mouse", "group", "age_weeks", "eta")],
  data.frame(trial = 1:10)
)
trials$correct <- rbinom(nrow(trials), 1, plogis(trials$eta + 0.06 * (trials$trial - 5)))
trials$eta <- NULL
trials <- trials[order(trials$mouse, trials$trial), ]

behavior <- mice[, c("mouse", "group", "age_weeks", "passed_probe")]
dir.create("project/AnalysisData", showWarnings = FALSE, recursive = TRUE)
write.csv(behavior, "project/AnalysisData/Behavior_simulated.csv", row.names = FALSE)
write.csv(trials, "project/AnalysisData/Behavior_trials_simulated.csv", row.names = FALSE)
