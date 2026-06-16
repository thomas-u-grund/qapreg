# Create dyadic data from a network object

Converts a network object into a dyadic data frame suitable for QAP
regression. The outcome variable is named `y`. Vertex attributes are
added as sender and receiver variables using `_i` and `_j` suffixes.
Edge attributes and user-supplied dyadic covariates are added as dyadic
variables.

## Usage

``` r
qap_dyads(
  net,
  directed = NULL,
  dyadic_covariates = NULL,
  missing_dyads = c("omit", "fail", "zero")
)
```

## Arguments

- net:

  A network object.

- directed:

  Logical; whether to treat the network as directed. If `NULL`, the
  directedness is taken from `net` using
  [`network::is.directed()`](https://rdrr.io/pkg/network/man/network.indicators.html).

- dyadic_covariates:

  Optional named list of dyadic covariate matrices. Each matrix must
  have dimensions `n` by `n`, where `n` is the number of vertices in
  `net`.

- missing_dyads:

  Character string specifying how missing dyads in the outcome network
  are handled. `"omit"` drops missing outcome dyads, `"fail"` stops if
  missing dyads are present, and `"zero"` treats missing dyads as zero.

## Value

A data frame with one row per dyad and at least the columns `y`, `i`,
and `j`. The returned data frame also contains attributes including
`dyads`, `ymat`, `n`, `directed`, `missing_dyads`, and `observed_mask`.

## See also

[`qapreg()`](qapreg.md), [`qaplogit()`](qaplogit.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(network)

net <- network::network(matrix(rbinom(25, 1, 0.2), 5, 5), directed = TRUE)
dat <- qap_dyads(net)
head(dat)
} # }
```
