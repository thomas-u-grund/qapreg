# Add supplied dyadic covariates to dyadic data

Looks up dyadic covariate values for each observed dyad and appends them
to a dyadic data frame.

## Usage

``` r
.qap_add_dyadic_covariates(dat, dyads, dyadic_covariates, n)
```

## Arguments

- dat:

  A dyadic data frame.

- dyads:

  A data frame with integer columns `i` and `j` identifying dyads.

- dyadic_covariates:

  Optional named list of `n` by `n` matrices.

- n:

  Number of vertices in the network.

## Value

The input data frame with additional covariate columns.
