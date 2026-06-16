# Compare qapreg and netlogit estimates

Compares coefficients and two-sided QAP p-values from a fitted `qapreg`
object with an equivalent
[`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html) model.

## Usage

``` r
compare_netlogit(
  object,
  net,
  reps = NULL,
  dyadic_covariates = NULL,
  missing_dyads = NULL,
  seed = NULL
)
```

## Arguments

- object:

  An object of class `"qapreg"`, usually returned by
  [`qapreg()`](qapreg.md) or [`qaplogit()`](qaplogit.md).

- net:

  The original network object used to fit `object`.

- reps:

  Optional number of permutations for the
  [`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html)
  comparison. Defaults to `object$reps`.

- dyadic_covariates:

  Optional named list of dyadic covariate matrices. These should match
  the covariates used to fit `object`.

- missing_dyads:

  Optional missing-dyad handling rule for the comparison. Defaults to
  `object$missing_dyads`.

- seed:

  Optional random seed used before fitting the comparison model.

## Value

A data frame comparing terms, coefficients, and two-sided QAP p-values.
The full [`sna::netlogit()`](https://rdrr.io/pkg/sna/man/netlogit.html)
object is stored as the `"netlogit"` attribute.

## See also

[`qap_netlogit_compare()`](qap_netlogit_compare.md),
[`qapreg()`](qapreg.md), [`qaplogit()`](qaplogit.md)

## Examples

``` r
if (FALSE) { # \dontrun{
fit <- qaplogit(net, y ~ Grade_i + Grade_j, reps = 100)
compare_netlogit(fit, net = net, reps = 100)
} # }
```
