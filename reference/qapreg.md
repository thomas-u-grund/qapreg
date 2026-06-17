# Quadratic Assignment Procedure regression

Fits a regression model to dyadic network data and evaluates coefficient
significance using node-label permutations under the Quadratic
Assignment Procedure (QAP).

## Usage

``` r
qapreg(
  net,
  formula,
  reps = 100,
  directed = NULL,
  dyadic_covariates = NULL,
  missing_dyads = c("omit", "fail", "zero"),
  na_action = c("omit", "fail", "pass"),
  permutation_missing = c("fixed", "dynamic"),
  fit_fun = stats::glm,
  fit_args = list(family = stats::binomial()),
  seed = NULL,
  save_permutations = TRUE,
  save_permutation_ses = TRUE,
  verbose = TRUE,
  parallel = FALSE,
  ncores = max(1, parallel::detectCores() - 1)
)
```

## Arguments

- net:

  A network object.

- formula:

  A model formula. The response should usually be `y`, the internally
  generated dyadic outcome. Predictors may include vertex attributes
  with `_i` and `_j` suffixes, edge attributes, and supplied dyadic
  covariates.

- reps:

  Number of QAP permutations.

- directed:

  Logical; whether to treat the network as directed. If `NULL`, the
  directedness is taken from `net` using
  [`network::is.directed()`](https://rdrr.io/pkg/network/man/network.indicators.html).

- dyadic_covariates:

  Optional named list of dyadic covariate matrices. Each matrix must
  have dimensions `n` by `n`.

- missing_dyads:

  Character string specifying how missing outcome dyads are handled. One
  of `"omit"`, `"fail"`, or `"zero"`.

- na_action:

  Character string specifying how missing values in model variables are
  handled. One of `"omit"`, `"fail"`, or `"pass"`.

- permutation_missing:

  Character string specifying whether the model uses a fixed dyad set
  across permutations or dynamically re-applies missingness handling in
  each permutation. `"fixed"` is the default and mirrors
  [`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html) more
  closely: the dyads used in the observed model are kept fixed and only
  the outcome network is permuted. `"dynamic"` re-applies
  missing-outcome and missing-covariate handling inside each
  permutation.

- fit_fun:

  Model-fitting function. Defaults to
  [`stats::glm()`](https://rdrr.io/r/stats/glm.html).

- fit_args:

  Named list of additional arguments passed to `fit_fun`.

- seed:

  Optional random seed used before generating permutations.

- save_permutations:

  Logical; if `TRUE`, store permuted coefficient estimates in the
  returned object.

- save_permutation_ses:

  Logical; if `TRUE`, store model-based standard errors from each
  permutation in the returned object.

- verbose:

  Logical; if `TRUE`, print progress messages during permutations.

- parallel:

  Logical; whether to run permutations in parallel.

- ncores:

  Number of CPU cores to use when `parallel = TRUE`.

## Value

An object of class `"qapreg"`, a list containing observed coefficients,
model-based standard errors, QAP standard errors, permutation covariance
matrix, one-sided and two-sided QAP p-values, the observed fitted model,
and information about the QAP settings.

## Details

QAP inference preserves network dependence by repeatedly permuting node
labels and refitting the model to the permuted outcome network. P-values
are computed from the empirical permutation distribution using a
plus-one correction.

The function is deliberately flexible: by changing `fit_fun` and
`fit_args`, users can fit models other than logistic regression,
provided the fitted model supports
[`stats::coef()`](https://rdrr.io/r/stats/coef.html) and, ideally,
[`stats::vcov()`](https://rdrr.io/r/stats/vcov.html).

By default, `permutation_missing = "fixed"` keeps the analysis dyad set
fixed across all permutations. This is recommended for comparability
with [`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html) and
for stable permutation-based standard errors. The older behaviour can be
recovered with `permutation_missing = "dynamic"`.

## See also

[`qaplogit()`](qaplogit.md), [`qap_dyads()`](qap_dyads.md),
[`compare_netlogit()`](compare_netlogit.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(network)

mat <- matrix(rbinom(100, 1, 0.2), 10, 10)
diag(mat) <- 0
net <- network::network(mat, directed = TRUE)

fit <- qapreg(
  net,
  y ~ i + j,
  reps = 50,
  permutation_missing = "fixed",
  verbose = FALSE
)
print(fit)
} # }
```
