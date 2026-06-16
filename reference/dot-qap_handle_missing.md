# Handle missing model values in dyadic data

Applies a missing-value rule to the model frame implied by a formula and
dyadic data set.

## Usage

``` r
.qap_handle_missing(dat, formula, na_action = c("omit", "fail", "pass"))
```

## Arguments

- dat:

  A dyadic data frame, usually produced by
  [`qap_dyads()`](qap_dyads.md).

- formula:

  A model formula.

- na_action:

  Character string specifying how missing model values should be
  handled. One of `"omit"`, `"fail"`, or `"pass"`.

## Value

A dyadic data frame, possibly with rows omitted. Attributes storing dyad
indices and observed masks are updated where applicable.
