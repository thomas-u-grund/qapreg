# Add vertex and edge attributes to dyadic data

Extracts vertex attributes as sender/receiver variables and edge
attributes as dyadic variables.

## Usage

``` r
.qap_extract_network_attributes(net, dyads, dat)
```

## Arguments

- net:

  A network object.

- dyads:

  A data frame with integer columns `i` and `j` identifying dyads.

- dat:

  A dyadic data frame to which attributes will be added.

## Value

The input data frame with additional attribute columns.
