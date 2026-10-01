# One row per fitted brms model: worst-case Rhat, smallest bulk/tail ESS, and
# the number of divergent transitions, judged against the thresholds used
# throughout the book (Rhat < 1.01, both ESS > 400, zero divergences).
#
# fits: a named list of brmsfit objects, e.g. list("DPI only" = fit1, ...).
mcmc_check <- function(fits) {
  rows <- lapply(names(fits), function(nm) {
    fit <- fits[[nm]]
    draws <- posterior::summarise_draws(
      posterior::as_draws_df(fit), "rhat", "ess_bulk", "ess_tail"
    )
    draws <- draws[!draws$variable %in% c("lp__", "lprior"), ]
    n_div <- sum(subset(brms::nuts_params(fit), Parameter == "divergent__")$Value)
    data.frame(
      model = nm,
      max_rhat = max(draws$rhat, na.rm = TRUE),
      min_ess_bulk = min(draws$ess_bulk, na.rm = TRUE),
      min_ess_tail = min(draws$ess_tail, na.rm = TRUE),
      divergences = n_div,
      ok = max(draws$rhat, na.rm = TRUE) < 1.01 &&
        min(draws$ess_bulk, na.rm = TRUE) > 400 &&
        min(draws$ess_tail, na.rm = TRUE) > 400 &&
        n_div == 0
    )
  })
  do.call(rbind, rows)
}
