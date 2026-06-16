# Extract model-based standard errors

Attempts to extract standard errors from a fitted model using
[`stats::vcov()`](https://rdrr.io/r/stats/vcov.html). If extraction
fails, returns `NA` values of the expected length.

## Usage

``` r
.qap_model_se(fit, coef_names)
```

## Arguments

- fit:

  A fitted model object.

- coef_names:

  Character vector of coefficient names.

## Value

A named numeric vector of standard errors.
