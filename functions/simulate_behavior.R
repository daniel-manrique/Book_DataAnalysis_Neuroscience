# Simulated behavioral dataset: memory-probe task after a treatment
#
# 60 mice (30 vehicle, 30 treated), ages 8-30 weeks. Each mouse runs 10 training
# trials (correct / incorrect) and one final probe (passed / not passed).
# Every mouse has its own baseline ability (u_i ~ Normal(0, 0.8) on the logit
# scale), which is what makes trials from the same mouse non-independent.
#
# Two files are written to project/AnalysisData/:
#   Behavior_simulated.csv         one row per mouse                  -> ch. 3.6, 3.8
#                                  (passed_probe: ch. 3.6; time_in_zone: ch. 3.8)
#   Behavior_trials_simulated.csv  one row per trial                  -> ch. 3.8, 4.3
#                                  (correct: 3.8, 4.3; reaction_time_s: 3.8, 4.3)
#
# The 2026 stream (seed 2026) generates the cohort, passed_probe and correct.
# The 3.8 extension (time_in_zone, reaction_time_s) uses a separate seed (2028)
# after it, so the older columns never change when the script is re-run.
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

# ---- Extension for ch. 3.8 (added after 3.6/3.7) ------------------------------
# Everything below draws from a SECOND, independent stream (seed 2028), placed
# after all the draws above, so passed_probe and correct are byte-for-byte what
# they were when ch. 3.6 was written (its cached brms fits stay valid).
set.seed(2028)

# (a) Open-field test, one row per mouse: proportion of the session spent in the
#     centre zone. A genuinely continuous proportion in (0, 1) with no trial
#     count behind it -> beta regression. Mean-precision parametrization:
#     y ~ Beta(mu * phi, (1 - mu) * phi), logit(mu) linear in group and age.
zone_b0    <- -0.6   # vehicle mouse of 19 weeks (mu ~ 0.35)
zone_trt   <-  0.5   # treatment: more time in the centre
zone_age   <- -0.03  # per week, centered at 19 weeks
zone_phi   <- 15     # precision (larger = tighter around mu)
mice$mu_zone <- plogis(zone_b0 + zone_trt * (mice$group == "treated") +
                         zone_age * (mice$age_weeks - 19))
mice$time_in_zone <- rbeta(n_mice, mice$mu_zone * zone_phi,
                           (1 - mice$mu_zone) * zone_phi)

# (b) Reaction time (s) on every trial. Modeled on the log scale:
#     log(RT) = base + group + age + practice + mouse speed + noise, and
#     with probability p_lapse a trial is a lapse of attention: the RT is
#     multiplied by a factor between 3 and 8. Mouse-level speed is shared by
#     its 10 trials (non-independence, the point of ch. 4.3).
rt_base    <- log(0.6)  # vehicle mouse of 19 weeks, trial 5
rt_trt     <- -0.10     # treated mice are ~10% faster
rt_age     <-  0.012    # per week, centered at 19 weeks
rt_trial   <- -0.015    # practice, per trial, centered at trial 5
sd_speed   <-  0.15     # between-mouse sd of log baseline speed
sd_rt      <-  0.20     # within-mouse sd on the log scale
p_lapse    <-  0.06

mice$speed <- rnorm(n_mice, 0, sd_speed)
i <- match(trials$mouse, mice$mouse)
log_rt <- rt_base + rt_trt * (trials$group == "treated") +
  rt_age * (trials$age_weeks - 19) + rt_trial * (trials$trial - 5) +
  mice$speed[i] + rnorm(nrow(trials), 0, sd_rt)
lapse <- rbinom(nrow(trials), 1, p_lapse) == 1
log_rt[lapse] <- log_rt[lapse] + log(runif(sum(lapse), 3, 8))
trials$reaction_time_s <- round(exp(log_rt), 3)

behavior <- mice[, c("mouse", "group", "age_weeks", "passed_probe", "time_in_zone")]
behavior$time_in_zone <- round(behavior$time_in_zone, 4)
dir.create("project/AnalysisData", showWarnings = FALSE, recursive = TRUE)
write.csv(behavior, "project/AnalysisData/Behavior_simulated.csv", row.names = FALSE)
write.csv(trials, "project/AnalysisData/Behavior_trials_simulated.csv", row.names = FALSE)
