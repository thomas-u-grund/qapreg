# Logistic QAP Regression

Fits a logistic QAP regression model. The function supports both the
package's formula interface and a `netlogit`-style matrix interface.

## Usage

``` r
qaplogit(
  net,
  formula,
  reps = 100,
  directed = NULL,
  dyadic_covariates = NULL,
  missing_dyads = c("omit", "fail", "zero"),
  na_action = c("omit", "fail", "pass"),
  permutation_missing = c("fixed", "dynamic"),
  seed = NULL,
  save_permutations = TRUE,
  save_permutation_ses = TRUE,
  verbose = TRUE,
  intercept = TRUE,
  mode = c("digraph", "graph"),
  diag = FALSE,
  nullhyp = c("qap", "qapy", "classical"),
  test.statistic = c("beta", "z-value"),
  tol = 1e-07,
  ...
)
```

## Arguments

- net:

  A `network` object, or a response adjacency matrix when using the
  `netlogit`-style interface.

- formula:

  A model formula, or a matrix/array/list of predictors when using the
  `netlogit`-style interface.

- reps:

  Number of QAP permutations.

- directed:

  Logical; whether the network is directed.

- dyadic_covariates:

  Optional named list of dyadic covariate matrices.

- missing_dyads:

  Handling of missing dyads: `"omit"`, `"fail"`, or `"zero"`.

- na_action:

  Handling of missing model values: `"omit"`, `"fail"`, or `"pass"`.

- permutation_missing:

  Character string specifying whether missingness is handled using a
  fixed dyad set across permutations or dynamically inside each
  permutation. See [`qapreg()`](qapreg.md).

- seed:

  Optional random seed.

- save_permutations:

  Logical; store permuted coefficients.

- save_permutation_ses:

  Logical; store permuted standard errors.

- verbose:

  Logical; print progress messages.

- intercept:

  Logical; include intercept in `netlogit`-style models.

- mode:

  Character; `"digraph"` for directed networks or `"graph"` for
  undirected networks.

- diag:

  Logical; currently accepted for compatibility. Diagonal dyads are not
  modelled by `qapreg`.

- nullhyp:

  Character; currently `"qap"` and `"qapy"` use QAP-style
  response-network permutations. `"classical"` fits the observed
  logistic regression without interpreting QAP p-values.

- test.statistic:

  Character; accepted for compatibility. Current QAP p-values are based
  on coefficients.

- tol:

  Tolerance passed to
  [`glm.control()`](https://rdrr.io/r/stats/glm.control.html).

- ...:

  Additional arguments passed to
  [`glm()`](https://rdrr.io/r/stats/glm.html).

## Value

An object of class `"qapreg"`.
