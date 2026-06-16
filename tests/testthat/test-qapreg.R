make_test_network <- function() {
  net <- network::network.initialize(4, directed = TRUE)

  network::add.edges(
    net,
    tail = c(1, 1, 2, 3),
    head = c(2, 3, 4, 4)
  )

  net
}

test_that("qap_dyads returns dyadic data", {
  net <- make_test_network()

  dat <- qap_dyads(net)

  expect_s3_class(dat, "data.frame")
  expect_true("y" %in% names(dat))
  expect_true("i" %in% names(dat))
  expect_true("j" %in% names(dat))
  expect_equal(nrow(dat), 12)
})

test_that("qaplogit returns qapreg object", {
  net <- make_test_network()

  fit <- qaplogit(
    net = net,
    formula = y ~ i + j,
    reps = 10,
    seed = 123,
    verbose = FALSE
  )

  expect_s3_class(fit, "qapreg")
  expect_named(coef(fit), c("(Intercept)", "i", "j"))
})

test_that("vcov returns covariance matrix", {
  net <- make_test_network()

  fit <- qaplogit(
    net = net,
    formula = y ~ i + j,
    reps = 10,
    seed = 123,
    verbose = FALSE
  )

  V <- vcov(fit)

  expect_true(is.matrix(V))
  expect_equal(nrow(V), length(coef(fit)))
  expect_equal(ncol(V), length(coef(fit)))
})

test_that("confint returns confidence intervals", {
  net <- make_test_network()

  fit <- qaplogit(
    net = net,
    formula = y ~ i + j,
    reps = 10,
    seed = 123,
    verbose = FALSE
  )

  ci <- confint(fit)

  expect_true(is.matrix(ci))
  expect_equal(nrow(ci), length(coef(fit)))
  expect_equal(ncol(ci), 2)
})
