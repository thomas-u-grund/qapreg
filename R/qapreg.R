# qapreg.R

# ============================================================
# qapreg: QAP regression for statnet network objects
# ============================================================

#' qapreg: QAP regression for statnet network objects
#'
#' Tools for preparing dyadic data from \pkg{network} objects and estimating
#' regression models with Quadratic Assignment Procedure (QAP) inference.
#'
#' @name qapreg-package
#' @keywords internal
#' @importFrom stats coef confint complete.cases cov delete.response glm model.frame model.matrix na.pass qnorm sd terms vcov
NULL


# ------------------------------------------------------------
# Internal helpers
# ------------------------------------------------------------

#' Require the network package
#'
#' Checks whether the \pkg{network} package is installed and stops with an
#' informative error if it is unavailable.
#'
#' @return Invisibly returns nothing. Called for its side effect of validating
#'   that \pkg{network} is available.
#' @keywords internal
.qap_require_network <- function() {
  if (!requireNamespace("network", quietly = TRUE)) {
    stop("Package 'network' is required.", call. = FALSE)
  }
}


#' Extract an adjacency matrix from a network object
#'
#' Converts a \pkg{network} object to an adjacency matrix, attempting to retain
#' missing dyads where supported.
#'
#' @param net A \pkg{network} object.
#'
#' @return An adjacency matrix for `net`.
#' @keywords internal
.qap_adjacency <- function(net) {
  .qap_require_network()

  out <- tryCatch(
    network::as.matrix.network.adjacency(net, na.omit = FALSE),
    error = function(e) network::as.matrix.network.adjacency(net)
  )

  out
}


#' Validate dyadic covariate matrices
#'
#' Checks that dyadic covariates are supplied as a named list of `n` by `n`
#' matrices.
#'
#' @param dyadic_covariates A named list of dyadic covariate matrices, or `NULL`.
#' @param n Number of vertices in the network.
#'
#' @return Invisibly returns `TRUE` if validation succeeds.
#' @keywords internal
.qap_validate_dyadic_covariates <- function(dyadic_covariates, n) {
  if (is.null(dyadic_covariates)) {
    return(invisible(TRUE))
  }

  if (!is.list(dyadic_covariates) || is.null(names(dyadic_covariates))) {
    stop("dyadic_covariates must be a named list of n x n matrices.", call. = FALSE)
  }

  if (any(names(dyadic_covariates) == "")) {
    stop("All dyadic_covariates must be named.", call. = FALSE)
  }

  for (a in names(dyadic_covariates)) {
    mat <- dyadic_covariates[[a]]

    if (!is.matrix(mat)) {
      stop("Dyadic covariate '", a, "' must be a matrix.", call. = FALSE)
    }

    if (!all(dim(mat) == c(n, n))) {
      stop(
        "Dyadic covariate '", a, "' must have dimensions ",
        n, " x ", n, ".",
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}


#' Extract model-based standard errors
#'
#' Attempts to extract standard errors from a fitted model using [stats::vcov()].
#' If extraction fails, returns `NA` values of the expected length.
#'
#' @param fit A fitted model object.
#' @param coef_names Character vector of coefficient names.
#'
#' @return A named numeric vector of standard errors.
#' @keywords internal
.qap_model_se <- function(fit, coef_names) {
  se <- tryCatch(
    sqrt(diag(stats::vcov(fit))),
    error = function(e) rep(NA_real_, length(coef_names))
  )

  names(se) <- coef_names
  se
}


#' Fit a model using a supplied fitting function
#'
#' Calls a model-fitting function with a formula, data frame, and additional
#' arguments.
#'
#' @param formula A model formula.
#' @param data A data frame used for model estimation.
#' @param fit_fun A model-fitting function such as [stats::glm()] or
#'   [stats::lm()].
#' @param fit_args A named list of additional arguments passed to `fit_fun`.
#'
#' @return A fitted model object.
#' @keywords internal
.qap_fit <- function(formula, data, fit_fun, fit_args) {
  do.call(
    fit_fun,
    c(
      list(formula = formula, data = data),
      fit_args
    )
  )
}


#' Handle missing model values in dyadic data
#'
#' Applies a missing-value rule to the model frame implied by a formula and
#' dyadic data set.
#'
#' @param dat A dyadic data frame, usually produced by [qap_dyads()].
#' @param formula A model formula.
#' @param na_action Character string specifying how missing model values should
#'   be handled. One of `"omit"`, `"fail"`, or `"pass"`.
#'
#' @return A dyadic data frame, possibly with rows omitted. Attributes storing
#'   dyad indices and observed masks are updated where applicable.
#' @keywords internal
.qap_handle_missing <- function(dat,
                                formula,
                                na_action = c("omit", "fail", "pass")) {
  na_action <- match.arg(na_action)

  if (na_action == "pass") {
    return(dat)
  }

  dyads <- attr(dat, "dyads")
  observed_mask <- attr(dat, "observed_mask")

  mf <- stats::model.frame(
    formula = formula,
    data = dat,
    na.action = stats::na.pass
  )

  missing_rows <- !stats::complete.cases(mf)

  attr(dat, "missing_model_rows") <- missing_rows

  if (!any(missing_rows)) {
    return(dat)
  }

  if (na_action == "fail") {
    stop(
      "Missing values detected in ",
      sum(missing_rows),
      " dyads used by the model.",
      call. = FALSE
    )
  }

  keep <- !missing_rows

  dat <- dat[keep, , drop = FALSE]

  if (!is.null(dyads)) {
    attr(dat, "dyads") <- dyads[keep, , drop = FALSE]
  }

  if (!is.null(observed_mask)) {
    attr(dat, "observed_mask") <- observed_mask[keep]
  }

  attr(dat, "missing_model_rows") <- missing_rows

  dat
}


#' Compute a permutation p-value
#'
#' Computes a QAP permutation p-value using a plus-one correction.
#'
#' @param perm_values Numeric vector of permuted statistic values.
#' @param obs_value Observed statistic value.
#' @param alternative Character string specifying the alternative hypothesis.
#'   One of `"less"`, `"greater"`, or `"two.sided"`.
#'
#' @return A numeric p-value, or `NA_real_` if there are no valid permutation
#'   values.
#' @keywords internal
.qap_p_value <- function(perm_values, obs_value, alternative) {
  valid <- !is.na(perm_values)
  m <- sum(valid)

  if (m == 0) {
    return(NA_real_)
  }

  if (alternative == "greater") {
    k <- sum(perm_values[valid] >= obs_value)
  } else if (alternative == "less") {
    k <- sum(perm_values[valid] <= obs_value)
  } else if (alternative == "two.sided") {
    k <- sum(abs(perm_values[valid]) >= abs(obs_value))
  } else {
    stop("Unknown alternative.", call. = FALSE)
  }

  (k + 1) / (m + 1)
}


#' Add vertex and edge attributes to dyadic data
#'
#' Extracts vertex attributes as sender/receiver variables and edge attributes
#' as dyadic variables.
#'
#' @param net A \pkg{network} object.
#' @param dyads A data frame with integer columns `i` and `j` identifying dyads.
#' @param dat A dyadic data frame to which attributes will be added.
#'
#' @return The input data frame with additional attribute columns.
#' @keywords internal
.qap_extract_network_attributes <- function(net, dyads, dat) {
  .qap_require_network()

  vattrs <- network::list.vertex.attributes(net)
  vattrs <- setdiff(vattrs, c("na", "vertex.names"))

  for (a in vattrs) {
    vals <- network::get.vertex.attribute(net, a)
    dat[[paste0(a, "_i")]] <- vals[dyads$i]
    dat[[paste0(a, "_j")]] <- vals[dyads$j]
  }

  eattrs <- network::list.edge.attributes(net)
  eattrs <- setdiff(eattrs, "na")

  for (a in eattrs) {
    amat <- network::as.matrix.network(net, attrname = a)
    dat[[a]] <- amat[cbind(dyads$i, dyads$j)]
  }

  dat
}


#' Add supplied dyadic covariates to dyadic data
#'
#' Looks up dyadic covariate values for each observed dyad and appends them to a
#' dyadic data frame.
#'
#' @param dat A dyadic data frame.
#' @param dyads A data frame with integer columns `i` and `j` identifying dyads.
#' @param dyadic_covariates Optional named list of `n` by `n` matrices.
#' @param n Number of vertices in the network.
#'
#' @return The input data frame with additional covariate columns.
#' @keywords internal
.qap_add_dyadic_covariates <- function(dat, dyads, dyadic_covariates, n) {
  .qap_validate_dyadic_covariates(dyadic_covariates, n)

  if (is.null(dyadic_covariates)) {
    return(dat)
  }

  for (a in names(dyadic_covariates)) {
    dat[[a]] <- dyadic_covariates[[a]][cbind(dyads$i, dyads$j)]
  }

  dat
}


# ------------------------------------------------------------
# Exported data-preparation function
# ------------------------------------------------------------

#' Create dyadic data from a network object
#'
#' Converts a \pkg{network} object into a dyadic data frame suitable for QAP
#' regression. The outcome variable is named `y`. Vertex attributes are added as
#' sender and receiver variables using `_i` and `_j` suffixes. Edge attributes and
#' user-supplied dyadic covariates are added as dyadic variables.
#'
#' @param net A \pkg{network} object.
#' @param directed Logical; whether to treat the network as directed. If `NULL`,
#'   the directedness is taken from `net` using [network::is.directed()].
#' @param dyadic_covariates Optional named list of dyadic covariate matrices.
#'   Each matrix must have dimensions `n` by `n`, where `n` is the number of
#'   vertices in `net`.
#' @param missing_dyads Character string specifying how missing dyads in the
#'   outcome network are handled. `"omit"` drops missing outcome dyads, `"fail"`
#'   stops if missing dyads are present, and `"zero"` treats missing dyads as
#'   zero.
#'
#' @return A data frame with one row per dyad and at least the columns `y`, `i`,
#'   and `j`. The returned data frame also contains attributes including `dyads`,
#'   `ymat`, `n`, `directed`, `missing_dyads`, and `observed_mask`.
#'
#' @examples
#' \dontrun{
#' library(network)
#'
#' net <- network::network(matrix(rbinom(25, 1, 0.2), 5, 5), directed = TRUE)
#' dat <- qap_dyads(net)
#' head(dat)
#' }
#'
#' @seealso [qapreg()], [qaplogit()]
#' @export
qap_dyads <- function(net,
                      directed = NULL,
                      dyadic_covariates = NULL,
                      missing_dyads = c("omit", "fail", "zero")) {
  .qap_require_network()

  missing_dyads <- match.arg(missing_dyads)

  if (is.null(directed)) {
    directed <- network::is.directed(net)
  }

  n <- network::network.size(net)
  ymat <- .qap_adjacency(net)

  if (missing_dyads == "fail" && anyNA(ymat)) {
    stop("Missing dyads detected in the outcome network.", call. = FALSE)
  }

  if (missing_dyads == "zero") {
    ymat[is.na(ymat)] <- 0
  }

  dyads <- expand.grid(i = seq_len(n), j = seq_len(n))
  dyads <- dyads[dyads$i != dyads$j, , drop = FALSE]

  if (!directed) {
    dyads <- dyads[dyads$i < dyads$j, , drop = FALSE]
  }

  y <- ymat[cbind(dyads$i, dyads$j)]
  observed_mask <- !is.na(y)

  if (missing_dyads == "omit") {
    dyads <- dyads[observed_mask, , drop = FALSE]
    y <- y[observed_mask]
    observed_mask <- observed_mask[observed_mask]
  }

  dat <- data.frame(
    y = y,
    i = dyads$i,
    j = dyads$j
  )

  dat <- .qap_extract_network_attributes(net, dyads, dat)
  dat <- .qap_add_dyadic_covariates(dat, dyads, dyadic_covariates, n)

  attr(dat, "dyads") <- dyads
  attr(dat, "ymat") <- ymat
  attr(dat, "n") <- n
  attr(dat, "directed") <- directed
  attr(dat, "missing_dyads") <- missing_dyads
  attr(dat, "observed_mask") <- observed_mask

  dat
}


# ------------------------------------------------------------
# Main estimator
# ------------------------------------------------------------

#' Quadratic Assignment Procedure regression
#'
#' Fits a regression model to dyadic network data and evaluates coefficient
#' significance using node-label permutations under the Quadratic Assignment
#' Procedure (QAP).
#'
#' @param net A \pkg{network} object.
#' @param formula A model formula. The response should usually be `y`, the
#'   internally generated dyadic outcome. Predictors may include vertex
#'   attributes with `_i` and `_j` suffixes, edge attributes, and supplied dyadic
#'   covariates.
#' @param reps Number of QAP permutations.
#' @param directed Logical; whether to treat the network as directed. If `NULL`,
#'   the directedness is taken from `net` using [network::is.directed()].
#' @param dyadic_covariates Optional named list of dyadic covariate matrices.
#'   Each matrix must have dimensions `n` by `n`.
#' @param missing_dyads Character string specifying how missing outcome dyads are
#'   handled. One of `"omit"`, `"fail"`, or `"zero"`.
#' @param na_action Character string specifying how missing values in model
#'   variables are handled. One of `"omit"`, `"fail"`, or `"pass"`.
#' @param fit_fun Model-fitting function. Defaults to [stats::glm()].
#' @param fit_args Named list of additional arguments passed to `fit_fun`.
#' @param seed Optional random seed used before generating permutations.
#' @param save_permutations Logical; if `TRUE`, store permuted coefficient
#'   estimates in the returned object.
#' @param save_permutation_ses Logical; if `TRUE`, store model-based standard
#'   errors from each permutation in the returned object.
#' @param verbose Logical; if `TRUE`, print progress messages during
#'   permutations.
#'
#' @return An object of class `"qapreg"`, a list containing observed
#'   coefficients, model-based standard errors, QAP standard errors,
#'   permutation covariance matrix, one-sided and two-sided QAP p-values, the
#'   observed fitted model, and information about the QAP settings.
#'
#' @details
#' QAP inference preserves network dependence by repeatedly permuting node labels
#' and refitting the model to the permuted outcome network. P-values are computed
#' from the empirical permutation distribution using a plus-one correction.
#'
#' The function is deliberately flexible: by changing `fit_fun` and `fit_args`,
#' users can fit models other than logistic regression, provided the fitted model
#' supports [stats::coef()] and, ideally, [stats::vcov()].
#'
#' @examples
#' \dontrun{
#' library(network)
#'
#' mat <- matrix(rbinom(100, 1, 0.2), 10, 10)
#' diag(mat) <- 0
#' net <- network::network(mat, directed = TRUE)
#'
#' fit <- qapreg(net, y ~ i + j, reps = 50, verbose = FALSE)
#' print(fit)
#' }
#'
#' @seealso [qaplogit()], [qap_dyads()], [compare_netlogit()]
#' @export
#' @importFrom stats coef confint model.frame model.matrix qnorm terms vcov complete.cases na.pass delete.response sd cov glm binomial glm.control
qapreg <- function(net,
                   formula,
                   reps = 100,
                   directed = NULL,
                   dyadic_covariates = NULL,
                   missing_dyads = c("omit", "fail", "zero"),
                   na_action = c("omit", "fail", "pass"),
                   fit_fun = stats::glm,
                   fit_args = list(family = stats::binomial()),
                   seed = NULL,
                   save_permutations = TRUE,
                   save_permutation_ses = TRUE,
                   verbose = TRUE) {
  .qap_require_network()

  missing_dyads <- match.arg(missing_dyads)
  na_action <- match.arg(na_action)

  if (!is.null(seed)) {
    set.seed(seed)
  }

  dat <- qap_dyads(
    net = net,
    directed = directed,
    dyadic_covariates = dyadic_covariates,
    missing_dyads = missing_dyads
  )

  dat <- .qap_handle_missing(
    dat = dat,
    formula = formula,
    na_action = na_action
  )

  dyads <- attr(dat, "dyads")
  ymat <- attr(dat, "ymat")
  n <- attr(dat, "n")
  directed <- attr(dat, "directed")

  fit_obs <- .qap_fit(
    formula = formula,
    data = dat,
    fit_fun = fit_fun,
    fit_args = fit_args
  )

  obs_coef <- stats::coef(fit_obs)
  terms <- names(obs_coef)

  obs_se <- .qap_model_se(fit_obs, terms)

  perm_coefs <- matrix(NA_real_, nrow = reps, ncol = length(terms))
  colnames(perm_coefs) <- terms

  perm_ses <- matrix(NA_real_, nrow = reps, ncol = length(terms))
  colnames(perm_ses) <- terms

  failed <- logical(reps)

  for (r in seq_len(reps)) {
    p <- sample(seq_len(n))

    yperm <- ymat[p, p]

    dat_perm <- dat
    dat_perm$y <- yperm[cbind(dyads$i, dyads$j)]

    if (missing_dyads == "omit") {
      keep <- !is.na(dat_perm$y)
      dat_perm <- dat_perm[keep, , drop = FALSE]
    }

    dat_perm <- .qap_handle_missing(
      dat = dat_perm,
      formula = formula,
      na_action = na_action
    )

    fit_perm <- try(
      .qap_fit(
        formula = formula,
        data = dat_perm,
        fit_fun = fit_fun,
        fit_args = fit_args
      ),
      silent = TRUE
    )

    if (inherits(fit_perm, "try-error")) {
      failed[r] <- TRUE
    } else {
      cf <- stats::coef(fit_perm)
      se <- .qap_model_se(fit_perm, names(cf))

      perm_coefs[r, names(cf)] <- cf
      perm_ses[r, names(se)] <- se
    }

    if (verbose && r %% max(1, floor(reps / 10)) == 0) {
      message("Permutation ", r, " / ", reps)
    }
  }

  qap_p_less <- sapply(terms, function(t) {
    .qap_p_value(perm_coefs[, t], obs_coef[t], alternative = "less")
  })

  qap_p_greater <- sapply(terms, function(t) {
    .qap_p_value(perm_coefs[, t], obs_coef[t], alternative = "greater")
  })

  qap_p_two_sided <- sapply(terms, function(t) {
    .qap_p_value(perm_coefs[, t], obs_coef[t], alternative = "two.sided")
  })

  qap_se <- apply(perm_coefs, 2, stats::sd, na.rm = TRUE)

  qap_cov <- stats::cov(
    perm_coefs,
    use = "pairwise.complete.obs"
  )

  out <- list(
    call = match.call(),
    formula = formula,
    directed = directed,
    reps = reps,
    failed_reps = sum(failed),
    missing_dyads = missing_dyads,
    na_action = na_action,
    coefficients = obs_coef,
    model_standard_errors = obs_se,
    qap_standard_errors = qap_se,
    qap_covariance = qap_cov,
    qap_p_less = qap_p_less,
    qap_p_greater = qap_p_greater,
    qap_p_two_sided = qap_p_two_sided,
    observed_model = fit_obs,
    valid_reps = colSums(!is.na(perm_coefs)),
    dyadic_covariates = names(dyadic_covariates)
  )

  if (save_permutations) {
    out$permuted_coefficients <- perm_coefs
  }

  if (save_permutation_ses) {
    out$permuted_standard_errors <- perm_ses
  }

  class(out) <- "qapreg"
  out
}


# ------------------------------------------------------------
# Logistic wrapper
# ------------------------------------------------------------

#' Logistic QAP regression
#'
#' Convenience wrapper around [qapreg()] for logistic regression with a binomial
#' link using [stats::glm()].
#'
#' @inheritParams qapreg
#' @param ... Additional arguments passed to [stats::glm()] through `fit_args`,
#'   such as `control = glm.control(maxit = 100)`.
#'
#' @return An object of class `"qapreg"`.
#'
#' @examples
#' \dontrun{
#' library(network)
#'
#' mat <- matrix(rbinom(100, 1, 0.2), 10, 10)
#' diag(mat) <- 0
#' net <- network::network(mat, directed = TRUE)
#'
#' fit <- qaplogit(net, y ~ i + j, reps = 50, verbose = FALSE)
#' summary(fit)
#' }
#'
#' @seealso [qapreg()]
#' @export
qaplogit <- function(net,
                     formula,
                     reps = 100,
                     directed = NULL,
                     dyadic_covariates = NULL,
                     missing_dyads = c("omit", "fail", "zero"),
                     na_action = c("omit", "fail", "pass"),
                     seed = NULL,
                     save_permutations = TRUE,
                     save_permutation_ses = TRUE,
                     verbose = TRUE,
                     ...) {
  fit_args <- c(
    list(family = stats::binomial()),
    list(...)
  )

  qapreg(
    net = net,
    formula = formula,
    reps = reps,
    directed = directed,
    dyadic_covariates = dyadic_covariates,
    missing_dyads = missing_dyads,
    na_action = na_action,
    fit_fun = stats::glm,
    fit_args = fit_args,
    seed = seed,
    save_permutations = save_permutations,
    save_permutation_ses = save_permutation_ses,
    verbose = verbose
  )
}


# ------------------------------------------------------------
# netlogit comparison
# ------------------------------------------------------------

#' Build full dyad data for netlogit comparison
#'
#' Constructs a full `n` by `n` dyadic data set, including diagonal entries, for
#' comparison with [sna::netlogit()].
#'
#' @param net A \pkg{network} object.
#' @param dyadic_covariates Optional named list of dyadic covariate matrices.
#' @param missing_dyads Character string specifying how missing outcome dyads are
#'   handled. One of `"omit"`, `"fail"`, or `"zero"`.
#'
#' @return A full dyadic data frame with attributes `ymat` and `n`.
#' @keywords internal
.qap_build_full_dyad_data <- function(net,
                                      dyadic_covariates = NULL,
                                      missing_dyads = c("omit", "fail", "zero")) {
  .qap_require_network()

  missing_dyads <- match.arg(missing_dyads)

  n <- network::network.size(net)
  ymat <- .qap_adjacency(net)

  if (missing_dyads == "fail" && anyNA(ymat)) {
    stop("Missing dyads detected in the outcome network.", call. = FALSE)
  }

  if (missing_dyads == "zero") {
    ymat[is.na(ymat)] <- 0
  }

  all_dyads <- expand.grid(i = seq_len(n), j = seq_len(n))

  dat <- data.frame(
    y = ymat[cbind(all_dyads$i, all_dyads$j)],
    i = all_dyads$i,
    j = all_dyads$j
  )

  dat <- .qap_extract_network_attributes(net, all_dyads, dat)
  dat <- .qap_add_dyadic_covariates(dat, all_dyads, dyadic_covariates, n)

  attr(dat, "ymat") <- ymat
  attr(dat, "n") <- n

  dat
}


#' Compare a QAP specification with sna::netlogit
#'
#' Fits an equivalent QAP logistic regression using [sna::netlogit()] for
#' comparison with this package's implementation.
#'
#' @param net A \pkg{network} object.
#' @param formula A model formula using the internally generated outcome `y`.
#' @param reps Number of QAP permutations.
#' @param dyadic_covariates Optional named list of dyadic covariate matrices.
#' @param missing_dyads Character string specifying how missing outcome dyads are
#'   handled. One of `"omit"`, `"fail"`, or `"zero"`.
#' @param seed Optional random seed used before fitting the comparison model.
#'
#' @return The fitted object returned by [sna::netlogit()].
#'
#' @details
#' This function is intended primarily as a diagnostic and validation aid.
#' Because [sna::netlogit()] operates on full adjacency matrices, exact
#' equivalence is easiest when there are no missing dyads or when
#' `missing_dyads = "zero"` is used.
#'
#' @examples
#' \dontrun{
#' library(network)
#' library(sna)
#'
#' mat <- matrix(rbinom(100, 1, 0.2), 10, 10)
#' diag(mat) <- 0
#' net <- network::network(mat, directed = TRUE)
#'
#' qap_netlogit_compare(net, y ~ i + j, reps = 50)
#' }
#'
#' @seealso [compare_netlogit()], [qapreg()], [qaplogit()]
#' @export
qap_netlogit_compare <- function(net,
                                 formula,
                                 reps = 100,
                                 dyadic_covariates = NULL,
                                 missing_dyads = c("omit", "fail", "zero"),
                                 seed = NULL) {
  .qap_require_network()

  if (!requireNamespace("sna", quietly = TRUE)) {
    stop("Package 'sna' is required for netlogit comparison.", call. = FALSE)
  }

  missing_dyads <- match.arg(missing_dyads)

  if (missing_dyads == "omit") {
    warning(
      "sna::netlogit works on full adjacency matrices. ",
      "For exact comparison, use missing_dyads = 'zero' or data with no missing dyads.",
      call. = FALSE
    )
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  full_dat <- .qap_build_full_dyad_data(
    net = net,
    dyadic_covariates = dyadic_covariates,
    missing_dyads = missing_dyads
  )

  y <- attr(full_dat, "ymat")
  n <- attr(full_dat, "n")

  terms_obj <- stats::terms(formula)

  mm <- stats::model.matrix(
    stats::delete.response(terms_obj),
    data = full_dat
  )

  mm <- mm[, colnames(mm) != "(Intercept)", drop = FALSE]

  if (ncol(mm) == 0) {
    stop("netlogit comparison requires at least one predictor.", call. = FALSE)
  }

  x <- array(NA_real_, dim = c(ncol(mm), n, n))
  dimnames(x)[[1]] <- colnames(mm)

  for (k in seq_len(ncol(mm))) {
    x[k, , ] <- matrix(mm[, k], nrow = n, ncol = n)
  }

  mode <- ifelse(network::is.directed(net), "digraph", "graph")

  sna::netlogit(
    y = y,
    x = x,
    nullhyp = "qap",
    reps = reps,
    mode = mode,
    diag = FALSE
  )
}


#' Compare qapreg and netlogit estimates
#'
#' Compares coefficients and two-sided QAP p-values from a fitted `qapreg` object
#' with an equivalent [sna::netlogit()] model.
#'
#' @param object An object of class `"qapreg"`, usually returned by [qapreg()] or
#'   [qaplogit()].
#' @param net The original \pkg{network} object used to fit `object`.
#' @param reps Optional number of permutations for the [sna::netlogit()]
#'   comparison. Defaults to `object$reps`.
#' @param dyadic_covariates Optional named list of dyadic covariate matrices.
#'   These should match the covariates used to fit `object`.
#' @param missing_dyads Optional missing-dyad handling rule for the comparison.
#'   Defaults to `object$missing_dyads`.
#' @param seed Optional random seed used before fitting the comparison model.
#'
#' @return A data frame comparing terms, coefficients, and two-sided QAP
#'   p-values. The full [sna::netlogit()] object is stored as the `"netlogit"`
#'   attribute.
#'
#' @examples
#' \dontrun{
#' fit <- qaplogit(net, y ~ Grade_i + Grade_j, reps = 100)
#' compare_netlogit(fit, net = net, reps = 100)
#' }
#'
#' @seealso [qap_netlogit_compare()], [qapreg()], [qaplogit()]
#' @export
compare_netlogit <- function(object,
                             net,
                             reps = NULL,
                             dyadic_covariates = NULL,
                             missing_dyads = NULL,
                             seed = NULL) {
  if (!inherits(object, "qapreg")) {
    stop("object must be a qapreg object.", call. = FALSE)
  }

  if (missing(net)) {
    stop("Please provide the original network object via net = ...", call. = FALSE)
  }

  if (is.null(reps)) {
    reps <- object$reps
  }

  if (is.null(missing_dyads)) {
    missing_dyads <- object$missing_dyads
  }

  nl <- qap_netlogit_compare(
    net = net,
    formula = object$formula,
    reps = reps,
    dyadic_covariates = dyadic_covariates,
    missing_dyads = missing_dyads,
    seed = seed
  )

  k <- min(length(object$coefficients), length(nl$coefficients))

  out <- data.frame(
    term = names(object$coefficients)[seq_len(k)],
    qapreg = as.numeric(object$coefficients[seq_len(k)]),
    netlogit = as.numeric(nl$coefficients[seq_len(k)]),
    qapreg_p_two_sided = as.numeric(object$qap_p_two_sided[seq_len(k)]),
    netlogit_p_two_sided = as.numeric(nl$pgreqabs[seq_len(k)])
  )

  attr(out, "netlogit") <- nl
  out
}


# ------------------------------------------------------------
# S3 methods
# ------------------------------------------------------------

#' Print a QAP regression object
#'
#' Prints coefficient estimates, model-based standard errors, QAP standard
#' errors, and QAP p-values for a fitted `qapreg` object.
#'
#' @param x An object of class `"qapreg"`.
#' @param digits Number of digits used for rounding printed output.
#' @param ... Additional arguments, currently ignored.
#'
#' @return Invisibly returns `x`.
#'
#' @method print qapreg
#' @export
print.qapreg <- function(x, digits = 4, ...) {
  out <- data.frame(
    estimate = x$coefficients,
    model_se = x$model_standard_errors,
    qap_se = x$qap_standard_errors,
    qap_p_less = x$qap_p_less,
    qap_p_greater = x$qap_p_greater,
    qap_p_two_sided = x$qap_p_two_sided
  )

  print(round(out, digits))

  if (x$failed_reps > 0) {
    message("Failed permutations: ", x$failed_reps, " / ", x$reps)
  }

  invisible(x)
}


#' Summarise a QAP regression object
#'
#' Prints a coefficient table, QAP settings, and the permutation covariance
#' matrix for a fitted `qapreg` object.
#'
#' @param object An object of class `"qapreg"`.
#' @param digits Number of digits used for rounding printed output.
#' @param ... Additional arguments, currently ignored.
#'
#' @return Invisibly returns `object`.
#'
#' @method summary qapreg
#' @export
summary.qapreg <- function(object, digits = 4, ...) {
  print(object, digits = digits)

  cat("\nQAP settings:\n")
  cat("  Repetitions: ", object$reps, "\n", sep = "")
  cat("  Directed: ", object$directed, "\n", sep = "")
  cat("  Missing dyads: ", object$missing_dyads, "\n", sep = "")
  cat("  Missing model values: ", object$na_action, "\n", sep = "")
  cat("  Failed repetitions: ", object$failed_reps, "\n", sep = "")

  cat("\nPermutation covariance matrix:\n")
  print(round(object$qap_covariance, digits))

  invisible(object)
}


#' Extract QAP regression coefficients
#'
#' Extracts observed model coefficients from a fitted `qapreg` object.
#'
#' @param object An object of class `"qapreg"`.
#' @param ... Additional arguments, currently ignored.
#'
#' @return A named numeric vector of coefficients.
#'
#' @method coef qapreg
#' @export
coef.qapreg <- function(object, ...) {
  object$coefficients
}


#' Extract a covariance matrix from a QAP regression object
#'
#' Returns either the permutation-based QAP covariance matrix or the covariance
#' matrix from the observed model fit.
#'
#' @param object An object of class `"qapreg"`.
#' @param type Character string specifying which covariance matrix to return.
#'   `"qap"` returns the permutation covariance matrix. `"model"` returns
#'   [stats::vcov()] from the observed model.
#' @param ... Additional arguments passed to methods.
#'
#' @return A covariance matrix.
#'
#' @method vcov qapreg
#' @export
vcov.qapreg <- function(object,
                        type = c("qap", "model"),
                        ...) {
  type <- match.arg(type)

  if (type == "qap") {
    return(object$qap_covariance)
  }

  stats::vcov(object$observed_model)
}


#' Confidence intervals for QAP regression coefficients
#'
#' Computes Wald-style confidence intervals using either QAP standard errors or
#' model-based standard errors.
#'
#' @param object An object of class `"qapreg"`.
#' @param parm Optional character vector of coefficient names. If `NULL`, all
#'   coefficients are used.
#' @param level Confidence level.
#' @param type Character string specifying the standard errors to use. `"qap"`
#'   uses permutation-based QAP standard errors. `"model"` uses model-based
#'   standard errors.
#' @param ... Additional arguments, currently ignored.
#'
#' @return A matrix with lower and upper confidence limits.
#'
#' @method confint qapreg
#' @export
confint.qapreg <- function(object,
                           parm = NULL,
                           level = 0.95,
                           type = c("qap", "model"),
                           ...) {
  type <- match.arg(type)

  beta <- stats::coef(object)

  if (is.null(parm)) {
    parm <- names(beta)
  }

  se <- if (type == "qap") {
    object$qap_standard_errors
  } else {
    object$model_standard_errors
  }

  alpha <- 1 - level
  z <- stats::qnorm(1 - alpha / 2)

  out <- cbind(
    beta[parm] - z * se[parm],
    beta[parm] + z * se[parm]
  )

  colnames(out) <- c(
    paste0(round(100 * alpha / 2, 1), "%"),
    paste0(round(100 * (1 - alpha / 2), 1), "%")
  )

  out
}


# ------------------------------------------------------------
# Example test
# ------------------------------------------------------------

# Uncomment to test interactively:
#
# library(network)
# library(ergm)
# library(sna)
#
# data(faux.mesa.high)
# net <- faux.mesa.high
#
# grade <- network::get.vertex.attribute(net, "Grade")
# grade_distance <- abs(outer(grade, grade, "-"))
#
# fit <- qaplogit(
#   net = net,
#   formula = y ~ Grade_i + Grade_j + Sex_i + Sex_j + grade_distance,
#   dyadic_covariates = list(
#     grade_distance = grade_distance
#   ),
#   reps = 100,
#   seed = 123,
#   verbose = FALSE,
#   control = glm.control(maxit = 100),
#   missing_dyads = "omit",
#   na_action = "omit"
# )
#
# print(fit)
# summary(fit)
# coef(fit)
# vcov(fit)
# confint(fit)
#
# comp <- compare_netlogit(
#   object = fit,
#   net = net,
#   reps = 100,
#   dyadic_covariates = list(
#     grade_distance = grade_distance
#   ),
#   seed = 123
# )
#
# comp
