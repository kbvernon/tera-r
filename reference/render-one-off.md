# One-Off Template Rendering

For rendering a single template file or string, it may be preferable to
use these one-off rendering options.

## Usage

``` r
render_template(path, ..., outfile = NULL, autoescape = TRUE)

render_string(string, ..., outfile = NULL, autoescape = TRUE)
```

## Arguments

- path:

  character scalar, path to a template file

- ...:

  specify context as key-value pairs where key is the template variable
  and value is the data to inject.

- outfile:

  character scalar, the path to file where template is to be rendered.
  If `NULL` (the default), it will render the template file to a string
  in the current R session.

- autoescape:

  boolean scalar, whether to autoescape HTML (default is `TRUE`).

- string:

  character scalar, the template string to render.

## Value

\`outfile“ (invisibly)

## Details

Requires a path to a template file, not a template string.

## Examples

``` r
tmp <- system.file("templates/hello.html", package = "tera")

# render to string
render_template(
  tmp,
  x = "world",
  y = "tera"
)
#> [1] "<p>Hello world. This is tera.</p>"

render_string(
  "<p>Hello {{ x }}. This is {{ y }}.</p>",
  x = "world",
  y = "tera"
)
#> [1] "<p>Hello world. This is tera.</p>"

# render to file
outfile <- file.path(tempdir(), "hello-rendered.html")
render_template(
  tmp,
  x = "world",
  y = "tera",
  outfile = outfile
)

readLines(outfile, warn = FALSE)
#> [1] "<p>Hello world. This is tera.</p>"
```
