# tera

The ‘tera’ package uses ‘extendr’ to provide access to Vincent
Prouillet’s ‘Tera’ templating engine in Rust. Users mainly interact with
a Tera R6 object, which serves as a template library with encapsulated
methods for rendering templates with a given context. Template syntax
supports additional logic, including built-in filters, tests, and
functions, as well as loops, conditions, and inheritance. Documentation
for Tera’s templating syntax can be found at
<https://keats.github.io/tera/>.

## Installation

The published CRAN version:

``` r
install.packages("tera")
```

The development version:

``` r
# install.packages("pak")
pak::pak("kbvernon/tera-r")
```

## Usage

Here is a simple hello-world example:

``` r
library(tera)

tera <- Tera$new()

tera$render_string(
  '<p>Hello {{ x }}. This is {{ y }}.</p>',
  x = "world",
  y = "tera"
)
#> [1] "<p>Hello world. This is tera.</p>"
```

To learn more, check out the [Getting
started](https://kbvernon.github.io/tera/articles/tera.html) article on
the package website, or call
[`vignette("tera")`](https://kbvernon.github.io/tera-r/articles/tera.md).
