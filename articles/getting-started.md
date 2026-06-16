# 

------------------------------------------------------------------------

title: “Getting Started with qapreg” output: rmarkdown::html_vignette
vignette: \> % % % ————————-

## Introduction

Networks violate one of the core assumptions of conventional regression
models: the independence of observations. When analysing dyadic
relationships, observations share actors and are therefore statistically
dependent.

The Quadratic Assignment Procedure (QAP) addresses this problem by
evaluating coefficient significance through repeated node-label
permutations. Instead of relying on conventional sampling assumptions,
QAP compares observed coefficients to a reference distribution generated
from randomly permuted versions of the network.

The `qapreg` package provides a formula-based interface for fitting QAP
regression models directly to `network` objects.

## Installation

``` r

# Development version
devtools::install_github("YOUR_GITHUB_USERNAME/qapreg")
```

## A Simple Example

We begin by creating a small directed network.

``` r

library(qapreg)
library(network)
#> 
#> 'network' 1.20.0 (2026-02-06), part of the Statnet Project
#> * 'news(package="network")' for changes since last version
#> * 'citation("network")' for citation information
#> * 'https://statnet.org' for help, support, and other information

net <- network.initialize(5, directed = TRUE)

add.edges(
  net,
  tail = c(1, 1, 2, 3, 4),
  head = c(2, 3, 4, 5, 5)
)
```

The package converts the network into a dyadic data set internally.

``` r

head(qap_dyads(net))
#>   y i j
#> 1 0 2 1
#> 2 0 3 1
#> 3 0 4 1
#> 4 0 5 1
#> 5 1 1 2
#> 6 0 3 2
```

## Fitting a QAP Logistic Regression

The simplest model uses only sender and receiver identifiers.

``` r

fit <- qaplogit(
  net = net,
  formula = y ~ i + j,
  reps = 100,
  seed = 123,
  verbose = FALSE
)

summary(fit)
#>             estimate model_se qap_se qap_p_less qap_p_greater qap_p_two_sided
#> (Intercept)  -1.4001   2.0556 0.0837     0.0396        0.9901          0.0396
#> i            -0.5114   0.4446 0.2599     0.0693        0.9505          0.0990
#> j             0.5114   0.4446 0.2599     1.0000        0.0198          0.0495
#> 
#> QAP settings:
#>   Repetitions: 100
#>   Directed: TRUE
#>   Missing dyads: omit
#>   Missing model values: omit
#>   Failed repetitions: 0
#> 
#> Permutation covariance matrix:
#>             (Intercept)       i       j
#> (Intercept)      0.0070  0.0032 -0.0032
#> i                0.0032  0.0675 -0.0675
#> j               -0.0032 -0.0675  0.0675
```

The output contains:

- Estimated coefficients
- Model-based standard errors
- QAP permutation standard errors
- One-sided and two-sided QAP p-values

## Extracting Results

Standard S3 methods are available.

``` r

coef(fit)
#> (Intercept)           i           j 
#>   -1.400141   -0.511367    0.511367
```

``` r

vcov(fit)
#>              (Intercept)            i            j
#> (Intercept)  0.007005407  0.003188634 -0.003188634
#> i            0.003188634  0.067524281 -0.067524281
#> j           -0.003188634 -0.067524281  0.067524281
```

``` r

confint(fit)
#>                     2.5%        97.5%
#> (Intercept) -1.564186443 -1.236095092
#> i           -1.020672200 -0.002061882
#> j            0.002061882  1.020672200
```

## Adding Dyadic Covariates

Many network analyses include dyadic predictors such as:

- Geographic distance
- Similarity measures
- Shared group membership
- Prior interactions

Dyadic covariates are supplied as matrices.

``` r

set.seed(123)

distance <- matrix(
  runif(25),
  nrow = 5,
  ncol = 5
)
```

These can be included directly in the model.

``` r

fit2 <- qaplogit(
  net = net,
  formula = y ~ i + j + distance,
  dyadic_covariates = list(
    distance = distance
  ),
  reps = 100,
  seed = 123,
  verbose = FALSE
)

summary(fit2)
#>             estimate model_se qap_se qap_p_less qap_p_greater qap_p_two_sided
#> (Intercept)  -0.9733   2.2161 1.5662     0.6535        0.3663          0.6832
#> i            -0.5222   0.4526 0.3275     0.0891        0.9307          0.1089
#> j             0.5814   0.4829 0.3576     0.9604        0.0594          0.0792
#> distance     -1.0923   1.7915 3.0264     0.2574        0.7624          0.5842
#> 
#> QAP settings:
#>   Repetitions: 100
#>   Directed: TRUE
#>   Missing dyads: omit
#>   Missing model values: omit
#>   Failed repetitions: 0
#> 
#> Permutation covariance matrix:
#>             (Intercept)       i       j distance
#> (Intercept)      2.4529  0.0718  0.0657  -4.5103
#> i                0.0718  0.1073 -0.1120   0.0125
#> j                0.0657 -0.1120  0.1279  -0.3106
#> distance        -4.5103  0.0125 -0.3106   9.1591
```

## Missing Data

The package distinguishes between two forms of missingness.

### Missing Dyads

Missing edges in the network itself are controlled through:

``` r

missing_dyads = "omit"
```

Available options are:

``` r

"omit"
"fail"
"zero"
```

### Missing Covariates

Missing values in model variables are handled using:

``` r

na_action = "omit"
```

Available options are:

``` r

"omit"
"fail"
"pass"
```

## Comparing Multiple Models

The package provides helper functions for comparing multiple QAP models.

``` r

compare_netlogit(model1, model2)
```

or

``` r

qap_netlogit_compare(model1, model2)
```

## Interpretation

A QAP coefficient is interpreted in the same way as the corresponding
coefficient in the underlying regression model.

The key difference lies in the significance assessment. Rather than
assuming independent observations, significance is evaluated against a
permutation distribution generated by repeatedly relabelling network
nodes.

Consequently, QAP p-values are generally more appropriate for network
data than conventional model-based p-values.

## References

Krackhardt, D. (1988). Predicting with networks: Nonparametric multiple
regression analysis of dyadic data. *Social Networks*, 10(4), 359–381.

Dekker, D., Krackhardt, D., & Snijders, T. A. B. (2007). Sensitivity of
MRQAP tests to collinearity and autocorrelation conditions.
*Psychometrika*, 72(4), 563–581.
