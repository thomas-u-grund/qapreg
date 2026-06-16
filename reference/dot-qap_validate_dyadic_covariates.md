# Validate dyadic covariate matrices

Checks that dyadic covariates are supplied as a named list of `n` by `n`
matrices.

## Usage

``` r
.qap_validate_dyadic_covariates(dyadic_covariates, n)
```

## Arguments

- dyadic_covariates:

  A named list of dyadic covariate matrices, or `NULL`.

- n:

  Number of vertices in the network.

## Value

Invisibly returns `TRUE` if validation succeeds.
