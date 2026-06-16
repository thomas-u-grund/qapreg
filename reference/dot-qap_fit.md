# Fit a model using a supplied fitting function

Calls a model-fitting function with a formula, data frame, and
additional arguments.

## Usage

``` r
.qap_fit(formula, data, fit_fun, fit_args)
```

## Arguments

- formula:

  A model formula.

- data:

  A data frame used for model estimation.

- fit_fun:

  A model-fitting function such as
  [`stats::glm()`](https://rdrr.io/r/stats/glm.html) or
  [`stats::lm()`](https://rdrr.io/r/stats/lm.html).

- fit_args:

  A named list of additional arguments passed to `fit_fun`.

## Value

A fitted model object.
