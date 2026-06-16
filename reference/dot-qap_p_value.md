# Compute a permutation p-value

Computes a QAP permutation p-value using a plus-one correction.

## Usage

``` r
.qap_p_value(perm_values, obs_value, alternative)
```

## Arguments

- perm_values:

  Numeric vector of permuted statistic values.

- obs_value:

  Observed statistic value.

- alternative:

  Character string specifying the alternative hypothesis. One of
  `"less"`, `"greater"`, or `"two.sided"`.

## Value

A numeric p-value, or `NA_real_` if there are no valid permutation
values.
