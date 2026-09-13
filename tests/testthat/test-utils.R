test_that("dots_to_json() unboxes scalars and keeps vectors as arrays", {
  expect_equal(dots_to_json(x = "world"), '{"x":"world"}')
  expect_equal(dots_to_json(n = 1L, flag = TRUE), '{"n":1,"flag":true}')
  expect_equal(dots_to_json(xs = c(1L, 2L, 3L)), '{"xs":[1,2,3]}')
  expect_equal(dots_to_json(obj = list(a = 1L)), '{"obj":{"a":1}}')
})

test_that("dots_to_json() handles an empty context", {
  expect_equal(dots_to_json(), "{}")
})

test_that("dots_to_json() rejects unnamed arguments", {
  expect_error(dots_to_json("world"), "must be named")
  expect_error(dots_to_json(x = "world", "unnamed"), "must be named")
})

test_that(".catch() passes non-conditions through unchanged", {
  expect_equal(.catch("a string"), "a string")
  expect_equal(.catch(list(1, 2)), list(1, 2))
  expect_null(.catch(NULL))
})

test_that(".catch() re-signals a thrown error, preserving its message", {
  expect_error(
    .catch(rlang::abort("something went wrong")),
    "something went wrong"
  )
})

test_that(".catch() reports the calling function", {
  caller <- function() .catch(rlang::abort("nope"))
  cnd <- rlang::catch_cnd(caller())
  expect_s3_class(cnd, "rlang_error")
  expect_equal(rlang::call_name(conditionCall(cnd)), "caller")
})

test_that("check_list_named() accepts named and empty lists", {
  expect_equal(check_list_named(list(a = 1, b = 2)), list(a = 1, b = 2))
  expect_equal(check_list_named(list()), list())
})

test_that("check_list_named() returns its input invisibly", {
  expect_invisible(check_list_named(list(a = 1)))
})

test_that("check_list_named() rejects partially or fully unnamed lists", {
  expect_error(check_list_named(list(1)), "must be named")
  expect_error(check_list_named(list(a = 1, 2)), "must be named")
  expect_error(
    check_list_named(setNames(list(1, 2), c("a", ""))),
    "must be named"
  )
})

test_that("check_files_exist() accepts files that exist", {
  tpl <- template("hello.html")
  expect_equal(check_files_exist(tpl), tpl)
  expect_invisible(check_files_exist(tpl))
  expect_equal(check_files_exist(list(a = tpl)), list(a = tpl))
})

test_that("check_files_exist() accepts an empty set of files", {
  expect_equal(check_files_exist(character()), character())
})

test_that("check_files_exist() reports missing files", {
  expect_error(check_files_exist("no/such/file.html"), "Could not find")
})

test_that("check_files_exist() pluralizes and names only the missing files", {
  tpl <- template("hello.html")
  expect_error(
    check_files_exist(c(tpl, "missing-one.html")),
    "Could not find template at 'missing-one.html'"
  )
  expect_error(
    check_files_exist(c("missing-one.html", "missing-two.html")),
    "Could not find templates at .*missing-one.*missing-two"
  )
  expect_error(
    check_files_exist(c(tpl, "missing-one.html")),
    regexp = "^(?!.*hello\\.html).*$",
    perl = TRUE
  )
})
