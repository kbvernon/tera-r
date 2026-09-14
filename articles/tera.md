# tera

This vignette walks through some of the basics of rendering templates
with Tera in R. Users mainly interact with a Tera R6 object, which
serves as a template library with encapsulated methods for rendering
templates with a given context.

A templating engine requires two things:

- a `template`, as you may have guessed, that includes variables and
  rendering logic describing where and how to inject data, and
- a `context`, or a set of variables and values to be injected into the
  template.

Templating syntax is described in the documentation for
[Tera](https://keats.github.io/tera/).

``` r
library(tera)
```

## Usage

To get a feel for what `tera` can do, let’s start with a simple “hello
world” example.

``` r
tera <- Tera$new()

tera$render_string(
  '<p>Hello {{ x }}. This is {{ y }}.</p>',
  x = "world",
  y = "tera"
)
```

    [1] "<p>Hello world. This is tera.</p>"

The syntax and API should look pretty familiar to anyone who has used
`glue` to do something like `glue::glue("Foo { x }", x = "bar")`. The
big difference is the object-oriented workflow.

## Initializing `Tera`

Everything in `tera` revolves around the `Tera` object, which serves as
a template library with encapsulated rendering methods. In the above
example, we initialize a `Tera` engine with an empty template library by
calling `Tera$new()` with no arguments.

If you have a complicated directory system with nested templates and
inheritance patterns - a common situation for web development, you may
find it easier to initialize an `tera` by specifying the directory with
a glob pattern. Suppose, for example, that you have a website directory
that looks like this:

``` r
template_dir <- system.file("templates", package = "tera")

cat(
  "website",
  list.files(template_dir, recursive = TRUE),
  sep = "\n- "
)
```

    website
    - base.html
    - blog/post.html
    - components.html
    - hello.html
    - index.html

You can generate a new `Tera` around this directory like so

``` r
tera <- Tera$new(file.path(template_dir, "**/*.html"))
tera
## ── Tera ──
## Template library:
## • base.html
## • blog/post.html
## • components.html
## • hello.html
## • index.html
## 
## Globals: 0
## Components: 2
## Autoescape: TRUE
## Delimiters: {% Block %}, {{ Variable }}, {# Comment #}
```

## Adding templates

Templates can be added from file or string.

``` r
# add templates manually from file
tera <- Tera$new()
tera$add_file_templates(
  "base.html" = file.path(template_dir, "base.html"),
  "index.html" = file.path(template_dir, "index.html")
)
tera
## ── Tera ──
## Template library:
## • base.html
## • index.html
## 
## Globals: 0
## Components: 0
## Autoescape: TRUE
## Delimiters: {% Block %}, {{ Variable }}, {# Comment #}

# add templates manually from string
tera$add_string_templates(
  img = '<img src="{{ img_src }}">'
)
tera
## ── Tera ──
## Template library:
## • base.html
## • img
## • index.html
## 
## Globals: 0
## Components: 0
## Autoescape: TRUE
## Delimiters: {% Block %}, {{ Variable }}, {# Comment #}
```

If you initialize a tera instance with a glob and then add more file
templates to the template directory, you can reload with the glob to
catch the new templates.

``` r
example_dir <- file.path(tempdir(), "tera-templates")
dir.create(example_dir)

file.copy(
  from = file.path(template_dir, "base.html"),
  to = file.path(example_dir, "base.html")
)
## [1] TRUE

tera <- Tera$new(file.path(example_dir, "*.html"))
tera
## ── Tera ──
## Template library:
## • base.html
## 
## Globals: 0
## Components: 0
## Autoescape: TRUE
## Delimiters: {% Block %}, {{ Variable }}, {# Comment #}

file.copy(
  from = file.path(template_dir, "index.html"),
  to = file.path(example_dir, "index.html")
)
## [1] TRUE

tera$reload()
tera
## ── Tera ──
## Template library:
## • base.html
## • index.html
## 
## Globals: 0
## Components: 0
## Autoescape: TRUE
## Delimiters: {% Block %}, {{ Variable }}, {# Comment #}
```

Reset to continue with built-in template examples.

``` r
tera <- Tera$new(file.path(template_dir, "**/*.html"))
```

## Rendering basics

Generally speaking, rendering a template involves supplying it with a
`context`, or a set of key-value pairs, with the keys being the variable
names - surrounded by `{{ variable }}` in the template - and their
values being the content to inject into the template. You can render a
template to string or to a file. Consider our hypothetical website’s
index template:

``` r
template_dir |>
  file.path("index.html") |>
  readLines(warn = FALSE) |>
  cat(sep = "\n")
```

    {% extends "base.html" %}
    {% block content %}
    <h1>{{ title }}</h1>
    <p>{{ p }}.</p>
    {% endblock content %}
    {% block footer %}
    <p>Copyright 2026 by {{ owner }}.</p>
    {% endblock footer %}

This has three variables: `{{ title }}`, `{{ p }}`, and `{{ owner }}`.
You can render this template to a string by passing it a context, a set
of values for those variables. Here we render the template to a string.

``` r
string <- tera$render_template(
  "index.html",
  title = "This is my blog",
  p = "Welcome to my awesome homepage.",
  owner = "Blake"
)

cat(string)
```

    <!DOCTYPE html>
    <html lang="en">
      <head></head>
      <body>
        <article>

    <h1>This is my blog</h1>
    <p>Welcome to my awesome homepage..</p>

        </article>
        <footer>

    <p>Copyright 2026 by Blake.</p>

        </footer>
      </body>
    </html>

You can also render a template to file by specifying `outfile`.

``` r
outfile <- file.path(tempdir(), "rendered-index.html")

tera$render_template(
  "index.html",
  title = "This is my blog",
  p = "Welcome to my awesome homepage.",
  owner = "Blake",
  outfile = outfile
)

cat(readLines(outfile, warn = FALSE), sep = "\n")
```

    <!DOCTYPE html>
    <html lang="en">
      <head></head>
      <body>
        <article>

    <h1>This is my blog</h1>
    <p>Welcome to my awesome homepage..</p>

        </article>
        <footer>

    <p>Copyright 2026 by Blake.</p>

        </footer>
      </body>
    </html>

And you can render a specific block in a template:

``` r
string <- tera$render_template(
  "index.html",
  title = "This is my blog",
  p = "Welcome to my awesome homepage.",
  owner = "Blake",
  block = "content"
)

cat(string)
```

    <h1>This is my blog</h1>
    <p>Welcome to my awesome homepage..</p>

You can also render individual components defined in one of your
templates, for example

``` r
string <- tera$render_component(
  "widget",
  title = "foo",
  body = "<p>This is a widget!</p>"
)

cat(string)
```

    <div class="widget">
        <h3>foo</h3>
        <p>This is a widget!</p>
    </div>

And you can bypass library templates altogether and pass a template
string directly

``` r
string <- tera$render_string(
  '<img src="{{ img_src }}">',
  img_src = "foo/bar.svg"
)

cat(string)
```

    <img src="foo/bar.svg">

Two helper functions are also provided if you want to render a one-off
template without going throught he process of initializing a tera
instance. The
[`render_template()`](https://kbvernon.github.io/tera-r/reference/render-one-off.md)
function will render a template file, and
[`render_string()`](https://kbvernon.github.io/tera-r/reference/render-one-off.md)
will render a string, same as the methods, but without the explicit tera
instance.

## Inspecting the library

There are some tools for inspecting the library. You can get a list of
templates and components in the library and a list of variables in a
specific template.

``` r
tera$templates()
## [1] "base.html"       "blog/post.html"  "components.html" "hello.html"     
## [5] "index.html"
tera$components()
## [1] "button" "widget"
tera$variables("index.html")
## [1] "owner" "p"     "title"
```

There is also the print method, which provides some of this information.

``` r
tera$print()
## ── Tera ──
## Template library:
## • base.html
## • blog/post.html
## • components.html
## • hello.html
## • index.html
## 
## Globals: 0
## Components: 2
## Autoescape: TRUE
## Delimiters: {% Block %}, {{ Variable }}, {# Comment #}
```

## Rendering logic

The `Tera` templating engine offers a lot of additional functionality,
like control flow and data manipulation. For example, the blog post
template shows how to construct a for loop and apply built-in filters
and functions.

``` r
template_dir |>
  file.path("blog", "post.html") |>
  readLines(warn = FALSE) |>
  cat(sep = "\n")
```

    {% extends "base.html" %}
    {% block content -%}
    <h1>{{ title }}</h1>
    <p>Last updated: {{ now() | date(format="%Y-%m-%d") }}.</p>
    <ul>
        {%- for product in products %}
        <li>{{ product.name }}: {{ product.price }}</li>
        {%- endfor %}
    </ul>
    {%- endblock content %}

In `{{ now() | date(format="%Y-%m-%d") }}`, `now()` is a function that
returns the current date and time. It’s returned value is then piped to
the [`date()`](https://rdrr.io/r/base/date.html) filter, which provides
formatting options. The template also has the for-loop construction
`{$ for product in products %}` that allows for looping over the
elements of a product table or array. When passed a data.frame, we get
this:

``` r
products <- data.frame(
  name = c("apple", "banana", "orange"),
  price = c(0.25, 0.4, 0.5)
)

string <- tera$render_template(
  "blog/post.html",
  title = "Fruit prices",
  products = products
)

cat(string)
```

    <!DOCTYPE html>
    <html lang="en">
      <head></head>
      <body>
        <article>
          <h1>Fruit prices</h1>
    <p>Last updated: 2026-09-14.</p>
    <ul>
        <li>apple: 0.25</li>
        <li>banana: 0.4</li>
        <li>orange: 0.5</li>
    </ul>
        </article>
        <footer>

        </footer>
      </body>
    </html>

## Autoescape

Tera escapes HTML by default:

``` r
string <- tera$render_string(
  "{{ html }}",
  html = "<script>alert('Hello World!')</script>"
)

cat(string)
```

    &lt;script&gt;alert(&#39;Hello World!&#39;)&lt;/script&gt;

For one-off rendering like the above, the function takes an autoescape
argument.

``` r
string <- tera$render_string(
  "{{ html }}",
  html = "<script>alert('Hello World!')</script>",
  autoescape = FALSE
)

cat(string)
```

    <script>alert('Hello World!')</script>

For rendering templates and components in the library, you can turn off
autoescape globally using `$autoescape_off()` and turn it back on with
`$autoescape_on()` (it is on by default).

``` r
tera$autoescape_off()
tera$autoescape_on()
```

## Delimiters

Templates are marked up with `{% blocks %}`, `{{ variables }}`, and
`{# comments #}`. You can change these with `$set_delimiters()`, though
only on an engine with an empty template library, so it must be done
before any templates are added.

``` r
alt <- Tera$new()

alt$set_delimiters(
  variable_start = "<<",
  variable_end = ">>"
)

alt$render_string("<< greeting >>, world!", greeting = "Hello")
```

    [1] "Hello, world!"

Each start delimiter must differ from the others, each delimiter must be
exactly two bytes long, and any delimiter left `NULL` is unchanged. Use
`$delimiters()` to see the current set.

``` r
alt$delimiters()
```

    $block_start
    [1] "{%"

    $block_end
    [1] "%}"

    $variable_start
    [1] "<<"

    $variable_end
    [1] ">>"

    $comment_start
    [1] "{#"

    $comment_end
    [1] "#}"

## Inheritance

Templates can inherit content from each other in one of two ways, either
using `include` or, for more complicated inheritance, `extends`.

``` r
string <- tera$render_string(
  '{%- include "index.html" -%}',
  title = "This is my blog",
  p = "Welcome to my awesome homepage.",
  owner = "Blake"
)

cat(string)
```


    <h1>This is my blog</h1>
    <p>Welcome to my awesome homepage..</p>


    <p>Copyright 2026 by Blake.</p>

The extension mechanism is a little more involved, requiring that you
specify content blocks where content from a child document should be
injected. We have actually been using this method in the examples
already. Our current library has `base.html`:

``` r
template_dir |>
  file.path("base.html") |>
  readLines(warn = FALSE) |>
  cat(sep = "\n")
```

    <!DOCTYPE html>
    <html lang="en">
      <head></head>
      <body>
        <article>
          {% block content %}{% endblock content %}
        </article>
        <footer>
          {% block footer %}{% endblock footer %}
        </footer>
      </body>
    </html>

Notice it has two `{% block ... %}`. This is where a child document
inserts content. And here is `index.html`:

``` r
template_dir |>
  file.path("index.html") |>
  readLines(warn = FALSE) |>
  cat(sep = "\n")
```

    {% extends "base.html" %}
    {% block content %}
    <h1>{{ title }}</h1>
    <p>{{ p }}.</p>
    {% endblock content %}
    {% block footer %}
    <p>Copyright 2026 by {{ owner }}.</p>
    {% endblock footer %}

Notice it has `{% extends "base.html" %}`. This makes it a child
document of `base.html`.

``` r
tera <- Tera$new(file.path(template_dir, "**/*.html"))

string <- tera$render_template(
  "index.html",
  title = "This is my blog",
  p = "Welcome to my awesome homepage.",
  owner = "Blake"
)

cat(string)
```

    <!DOCTYPE html>
    <html lang="en">
      <head></head>
      <body>
        <article>

    <h1>This is my blog</h1>
    <p>Welcome to my awesome homepage..</p>

        </article>
        <footer>

    <p>Copyright 2026 by Blake.</p>

        </footer>
      </body>
    </html>
