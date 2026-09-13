test_that("$new() creates an engine with an empty library", {
  tera <- Tera$new()
  expect_s3_class(tera, "Tera")
  expect_s3_class(tera, "R6")
  expect_length(tera$templates(), 0)
})

test_that("$new() builds a library from a glob", {
  tera <- Tera$new(file.path(template_dir(), "**/*.html"))
  expect_setequal(
    tera$templates(),
    list.files(template_dir(), recursive = TRUE)
  )
})

test_that("$add_file_templates() adds named templates from disk", {
  tera <- Tera$new()
  tera$add_file_templates(
    "base.html" = template("base.html"),
    "index.html" = template("index.html")
  )
  expect_setequal(tera$templates(), c("base.html", "index.html"))
})

test_that("$add_string_templates() adds named string templates", {
  tera <- Tera$new()
  tera$add_string_templates(
    img = '<img src="{{ img_src }}">',
    greeting = "Hello {{ x }}"
  )
  expect_setequal(tera$templates(), c("img", "greeting"))
})

test_that("$add_*_templates() rejects unnamed arguments", {
  tera <- Tera$new()
  expect_error(tera$add_file_templates(template("hello.html")))
  expect_error(tera$add_string_templates("{{ x }}"))
})

test_that("adding an invalid template errors", {
  tera <- Tera$new()
  expect_error(tera$add_string_templates(bad = "{% if %}"))
})

test_that("$reload() picks up new files matching the glob", {
  dir <- withr::local_tempdir()
  file.copy(from = template("hello.html"), to = file.path(dir, "hello.html"))
  tera <- Tera$new(file.path(dir, "*.html"))
  expect_setequal(tera$templates(), "hello.html")
  file.copy(template("base.html"), file.path(dir, "base.html"))
  tera$reload()
  expect_setequal(tera$templates(), c("hello.html", "base.html"))
})

test_that("$reload() preserves manually added templates", {
  dir <- withr::local_tempdir()
  file.copy(from = template("hello.html"), to = file.path(dir, "hello.html"))
  tera <- Tera$new(file.path(dir, "*.html"))
  tera$add_string_templates(foo = "{{ x }}")
  tera$reload()
  expect_true("foo" %in% tera$templates())
})

test_that("$render_template() renders a file template to a string", {
  tera <- Tera$new()
  tera$add_file_templates(hello = template("hello.html"))
  rendered <- tera$render_template("hello", x = "world", y = "Tera")
  expect_equal(rendered, "<p>Hello world. This is Tera.</p>")
})

test_that("$render_template() renders a file template to a file", {
  tera <- Tera$new()
  tera$add_file_templates(hello = template("hello.html"))
  outfile <- withr::local_tempfile(fileext = ".html")
  result <- tera$render_template(
    "hello",
    x = "world",
    y = "tera",
    outfile = outfile
  )
  expect_equal(result, outfile)
  expect_equal(read(outfile), "<p>Hello world. This is tera.</p>")
})

test_that("$render_template() renders a single block", {
  tera <- Tera$new(file.path(template_dir(), "*.html"))
  rendered <- tera$render_template(
    "index.html",
    title = "Index",
    p = "Welcome.",
    owner = "foo",
    block = "content"
  )
  expect_match(rendered, "<h1>Index</h1>", fixed = TRUE)
  expect_match(rendered, "Welcome.", fixed = TRUE)
  expect_no_match(rendered, "<!DOCTYPE html>", fixed = TRUE)
})

test_that("$render_string() renders a string template to a string", {
  tera <- Tera$new()
  rendered <- tera$render_string(
    '<img src="{{ img_src }}">',
    img_src = "foo/bar.svg"
  )
  expect_equal(rendered, '<img src="foo/bar.svg">')
})

test_that("$render_string() renders a string template to a file", {
  tera <- Tera$new()
  outfile <- withr::local_tempfile(fileext = ".html")
  result <- tera$render_string("{{ x }}", x = "a", outfile = outfile)
  expect_equal(result, outfile)
  expect_equal(read(outfile), "a")
})

test_that("$render_string() honors the autoescape argument", {
  tera <- Tera$new()
  autoescaped <- tera$render_string("{{ x }}", x = "<b>")
  expect_equal(autoescaped, "&lt;b&gt;")
  asis <- tera$render_string("{{ x }}", x = "<b>", autoescape = FALSE)
  expect_equal(asis, "<b>")
})

test_that("$render_component() renders a component with its arguments", {
  tera <- Tera$new()
  tera$add_file_templates("components.html" = template("components.html"))
  rendered <- tera$render_component("button", label = "Primary")
  expect_equal(rendered, '<button class="btn btn-primary">Primary</button>')
})

test_that("$render_component() injects the body", {
  tera <- Tera$new()
  tera$add_file_templates("components.html" = template("components.html"))
  rendered <- tera$render_component(
    "widget",
    title = "foo",
    body = "<p>This is a widget!</p>"
  )
  expect_match(rendered, "<h3>foo</h3>", fixed = TRUE)
  expect_match(rendered, "<p>This is a widget!</p>", fixed = TRUE)
})

test_that("$render_component() renders to a file", {
  tera <- Tera$new()
  tera$add_file_templates("components.html" = template("components.html"))
  outfile <- withr::local_tempfile(fileext = ".html")
  result <- tera$render_component(
    "button",
    label = "Primary",
    outfile = outfile
  )
  expect_equal(result, outfile)
  expect_equal(
    read(outfile),
    '<button class="btn btn-primary">Primary</button>'
  )
})

test_that("$templates() lists template names", {
  tera <- Tera$new()
  expect_length(tera$templates(), 0)
  tera$add_string_templates(a = "{{ x }}", b = "{{ y }}")
  expect_setequal(tera$templates(), c("a", "b"))
})

test_that("$components() lists component names", {
  tera <- Tera$new()
  expect_length(tera$components(), 0)
  tera$add_file_templates("components.html" = template("components.html"))
  expect_setequal(tera$components(), c("button", "widget"))
})

test_that("$variables() lists the variables used in a template", {
  tera <- Tera$new()
  tera$add_string_templates(a = "{{ x }} and {{ y }}")
  expect_setequal(tera$variables("a"), c("x", "y"))
})

test_that("$variables() returns an empty vector for a template with no variables", {
  tera <- Tera$new()
  tera$add_string_templates(a = "no variables here")
  expect_length(tera$variables("a"), 0)
})

test_that("$set_globals() records variable names and makes them available", {
  tera <- Tera$new()
  tera$add_string_templates(a = "{{ site_title }}")
  tera$set_globals(base_url = "https://example.com", site_title = "My Website")
  expect_setequal(tera$globals(), c("base_url", "site_title"))
  expect_equal(tera$render_template("a"), "My Website")
})

test_that("$globals() are visible to every template", {
  tera <- Tera$new()
  tera$set_globals(site = "example")
  tera$add_string_templates(a = "{{ site }}", b = "[{{ site }}]")
  expect_equal(tera$render_template("a"), "example")
  expect_equal(tera$render_template("b"), "[example]")
})

test_that("$set_globals() overrides an existing global without duplicating it", {
  tera <- Tera$new()
  tera$add_string_templates(a = "{{ site }}")
  tera$set_globals(site = "first")
  tera$set_globals(site = "second")
  expect_equal(tera$globals(), "site")
  expect_equal(tera$render_template("a"), "second")
})

test_that("$set_globals() accumulates across calls", {
  tera <- Tera$new()
  tera$set_globals(a = 1)
  tera$set_globals(b = 2)
  expect_setequal(tera$globals(), c("a", "b"))
})

test_that("a local context variable takes precedence over a global", {
  tera <- Tera$new()
  tera$add_string_templates(a = "{{ x }}")
  tera$set_globals(x = "global")
  expect_equal(tera$render_template("a", x = "local"), "local")
})

test_that("$globals() returns NULL for an engine with no globals", {
  expect_null(Tera$new()$globals())
})

test_that("$clear_globals() empties the global context", {
  tera <- Tera$new()
  tera$add_string_templates(a = "[{{ site | default(value='') }}]")
  tera$set_globals(site = "example")
  tera$clear_globals()
  expect_null(tera$globals())
  expect_equal(tera$render_template("a"), "[]")
})

test_that("autoescape is on by default for html templates", {
  tera <- Tera$new()
  tera$add_file_templates("hello.html" = template("hello.html"))
  autoescaped <- tera$render_template("hello.html", x = "&world", y = "b")
  expect_equal(autoescaped, "<p>Hello &amp;world. This is b.</p>")
})

test_that("$autoescape_off() disables escaping", {
  tera <- Tera$new()
  tera$add_file_templates("hello.html" = template("hello.html"))
  tera$autoescape_off()
  asis <- tera$render_template("hello.html", x = "&world", y = "b")
  expect_equal(asis, "<p>Hello &world. This is b.</p>")
})

test_that("$autoescape_on() re-enables escaping", {
  tera <- Tera$new()
  tera$add_file_templates("hello.html" = template("hello.html"))
  tera$autoescape_off()
  tera$autoescape_on()
  autoescaped <- tera$render_template("hello.html", x = "&world", y = "b")
  expect_equal(autoescaped, "<p>Hello &amp;world. This is b.</p>")
})

test_that("$delimiters() returns the tera defaults", {
  expect_equal(
    Tera$new()$delimiters(),
    list(
      block_start = "{%",
      block_end = "%}",
      variable_start = "{{",
      variable_end = "}}",
      comment_start = "{#",
      comment_end = "#}"
    )
  )
})

test_that("$set_delimiters() changes how templates are parsed", {
  tera <- Tera$new()
  tera$set_delimiters(variable_start = "<<", variable_end = ">>")
  tera$add_string_templates(a = "<< x >>")
  expect_equal(tera$render_template("a", x = "world"), "world")
})

test_that("$set_delimiters() leaves the default delimiters inert", {
  tera <- Tera$new()
  tera$set_delimiters(variable_start = "<<", variable_end = ">>")
  tera$add_string_templates(a = "{{ x }}")
  expect_equal(tera$render_template("a", x = "world"), "{{ x }}")
})

test_that("$set_delimiters() errors once templates have been added", {
  tera <- Tera$new()
  tera$add_string_templates(a = "{{ x }}")
  expect_error(tera$set_delimiters(variable_start = "<<"))
})

test_that("each engine keeps its own delimiters", {
  a <- Tera$new()
  b <- Tera$new()
  a$set_delimiters(variable_start = "<<", variable_end = ">>")
  expect_equal(b$delimiters()$variable_start, "{{")
})

test_that("each engine keeps its own template library", {
  a <- Tera$new()
  b <- Tera$new()
  a$add_string_templates(only_in_a = "{{ x }}")
  expect_length(b$templates(), 0)
})

test_that("methods mutate the engine in place", {
  tera <- Tera$new()
  mutate <- function(engine) engine$add_string_templates(a = "{{ x }}")
  mutate(tera)
  expect_setequal(tera$templates(), "a")
})
