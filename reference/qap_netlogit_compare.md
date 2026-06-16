# Compare a QAP specification with sna::netlogit

Fits an equivalent QAP logistic regression using
[`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html) for
comparison with this package's implementation.

## Usage

``` r
qap_netlogit_compare(
  net,
  formula,
  reps = 100,
  dyadic_covariates = NULL,
  missing_dyads = c("omit", "fail", "zero"),
  seed = NULL
)
```

## Arguments

- net:

  A network object.

- formula:

  A model formula using the internally generated outcome `y`.

- reps:

  Number of QAP permutations.

- dyadic_covariates:

  Optional named list of dyadic covariate matrices.

- missing_dyads:

  Character string specifying how missing outcome dyads are handled. One
  of `"omit"`, `"fail"`, or `"zero"`.

- seed:

  Optional random seed used before fitting the comparison model.

## Value

The fitted object returned by
[`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html).

## Details

This function is intended primarily as a diagnostic and validation aid.
Because [`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html)
operates on full adjacency matrices, exact equivalence is easiest when
there are no missing dyads or when `missing_dyads = "zero"` is used.

## See also

[`compare_netlogit()`](compare_netlogit.md), [`qapreg()`](qapreg.md),
[`qaplogit()`](qaplogit.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(network)
library(sna)

mat <- matrix(rbinom(100, 1, 0.2), 10, 10)
diag(mat) <- 0
net <- network::network(mat, directed = TRUE)

qap_netlogit_compare(net, y ~ i + j, reps = 50)
} # }
```
