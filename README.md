
# qapreg

<!-- badges: start -->

<!-- Add GitHub Actions and pkgdown badges later -->

<!-- badges: end -->

`qapreg` is an R package for fitting Quadratic Assignment Procedure
(QAP) regression models to network data.

The package provides a modern formula interface for QAP analysis of
`network` objects, allowing researchers to estimate dyadic regression
models while accounting for the dependence structure inherent in network
data.

## Features

- Formula-based model specification
- Logistic QAP regression via `qaplogit()`
- Support for dyadic covariate matrices
- Permutation-based significance testing
- Standard S3 methods (`print`, `summary`, `coef`, `vcov`, `confint`)
- Integration with the `network` package

## Installation

### Development version

``` r
remotes::install_github("thomas-u-grund/qapreg")
```

## Why QAP?

Standard regression models assume that observations are independent.

In network data, dyads share actors and are therefore statistically
dependent. This violates conventional inference assumptions and can lead
to misleading p-values.

QAP addresses this problem by repeatedly permuting node labels and
comparing observed coefficients against the resulting reference
distribution.

## A Simple Example

``` r
library(qapreg)
library(network)

net <- network.initialize(5, directed = TRUE)

add.edges(
  net,
  tail = c(1, 1, 2, 3, 4),
  head = c(2, 3, 4, 5, 5)
)

fit <- qaplogit(
  net = net,
  formula = y ~ i + j,
  reps = 100,
  seed = 123,
  verbose = FALSE
)

summary(fit)
```

## Dyadic Covariates

Dyadic predictors can be supplied as matrices.

``` r
distance <- matrix(
  runif(25),
  nrow = 5,
  ncol = 5
)

fit <- qaplogit(
  net = net,
  formula = y ~ i + j + distance,
  dyadic_covariates = list(
    distance = distance
  ),
  reps = 100,
  seed = 123,
  verbose = FALSE
)

summary(fit)
```

## Extracting Results

``` r
coef(fit)

vcov(fit)

confint(fit)
```

## Documentation

A full introduction is available in the package vignette:

``` r
browseVignettes("qapreg")
```

## Citation

If you use `qapreg` in published work, please cite the package.

## License

MIT License.
