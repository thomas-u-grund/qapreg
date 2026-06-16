# Build full dyad data for netlogit comparison

Constructs a full `n` by `n` dyadic data set, including diagonal
entries, for comparison with
[`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html).

## Usage

``` r
.qap_build_full_dyad_data(
  net,
  dyadic_covariates = NULL,
  missing_dyads = c("omit", "fail", "zero")
)
```

## Arguments

- net:

  A network object.

- dyadic_covariates:

  Optional named list of dyadic covariate matrices.

- missing_dyads:

  Character string specifying how missing outcome dyads are handled. One
  of `"omit"`, `"fail"`, or `"zero"`.

## Value

A full dyadic data frame with attributes `ymat` and `n`.
