# Extract a covariance matrix from a QAP regression object

Returns either the permutation-based QAP covariance matrix or the
covariance matrix from the observed model fit.

## Usage

``` r
# S3 method for class 'qapreg'
vcov(object, type = c("qap", "model"), ...)
```

## Arguments

- object:

  An object of class `"qapreg"`.

- type:

  Character string specifying which covariance matrix to return. `"qap"`
  returns the permutation covariance matrix. `"model"` returns
  [`stats::vcov()`](https://rdrr.io/r/stats/vcov.html) from the observed
  model.

- ...:

  Additional arguments passed to methods.

## Value

A covariance matrix.
