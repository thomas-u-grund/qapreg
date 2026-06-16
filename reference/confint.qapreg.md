# Confidence intervals for QAP regression coefficients

Computes Wald-style confidence intervals using either QAP standard
errors or model-based standard errors.

## Usage

``` r
# S3 method for class 'qapreg'
confint(object, parm = NULL, level = 0.95, type = c("qap", "model"), ...)
```

## Arguments

- object:

  An object of class `"qapreg"`.

- parm:

  Optional character vector of coefficient names. If `NULL`, all
  coefficients are used.

- level:

  Confidence level.

- type:

  Character string specifying the standard errors to use. `"qap"` uses
  permutation-based QAP standard errors. `"model"` uses model-based
  standard errors.

- ...:

  Additional arguments, currently ignored.

## Value

A matrix with lower and upper confidence limits.
