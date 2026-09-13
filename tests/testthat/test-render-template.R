test_that("render_template() renders a template file to a string", {
  rendered <- render_template(template("hello.html"), x = "world", y = "tera")
  expect_equal(rendered, "<p>Hello world. This is tera.</p>")
})

test_that("render_template() renders a template file to a file", {
  outfile <- withr::local_tempfile(fileext = ".html")
  result <- render_template(
    template("hello.html"),
    x = "world",
    y = "tera",
    outfile = outfile
  )
  expect_equal(result, outfile)
  expect_equal(read(outfile), "<p>Hello world. This is tera.</p>")
})

test_that("render_template() autoescapes html templates", {
  tpl <- withr::local_tempfile(lines = "{{ x }}", fileext = ".html")
  autoescaped <- render_template(tpl, x = "<b>&")
  expect_equal(autoescaped, "&lt;b&gt;&amp;\n")
})

test_that("render_template(autoescape = FALSE) renders html as is", {
  tpl <- withr::local_tempfile(lines = "{{ x }}", fileext = ".html")
  asis <- render_template(tpl, x = "<b>&", autoescape = FALSE)
  expect_equal(asis, "<b>&\n")
})

test_that("render_string() renders a string template to a string", {
  rendered <- render_string("Hello {{ x }}", x = "world")
  expect_equal(rendered, "Hello world")
})

test_that("render_string() renders a string template to a file", {
  outfile <- withr::local_tempfile(fileext = ".html")
  render_string("{{ x }}", x = "a", outfile = outfile)
  expect_equal(read(outfile), "a")
})

test_that("render_string() autoescapes by default", {
  autoescaped <- render_string("{{ x }}", x = "<b>&")
  expect_equal(autoescaped, "&lt;b&gt;&amp;")
})
