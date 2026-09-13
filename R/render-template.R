#' One-Off Template Rendering
#'
#' @description For rendering a single template file or string, it may be
#'   preferable to use these one-off rendering options.
#'
#' @param string character scalar, the template string to render.
#' @param path character scalar, path to a template file
#' @param ... specify context as key-value pairs where key is the template
#'   variable and value is the data to inject.
#' @param outfile character scalar, the path to file where template is to
#'   be rendered. If `NULL` (the default), it will render the template file to a
#'   string in the current R session.
#' @param autoescape boolean scalar, whether to autoescape HTML (default is
#'   `TRUE`).
#'
#' @return `outfile`` (invisibly)
#'
#' @details Requires a path to a template file, not a template string.
#'
#' @name render-one-off
#' @export
#' @examples
#' tmp <- system.file("templates/hello.html", package = "tera")
#'
#' # render to string
#' render_template(
#'   tmp,
#'   x = "world",
#'   y = "tera"
#' )
#'
#' render_string(
#'   "<p>Hello {{ x }}. This is {{ y }}.</p>",
#'   x = "world",
#'   y = "tera"
#' )
#'
#' # render to file
#' outfile <- file.path(tempdir(), "hello-rendered.html")
#' render_template(
#'   tmp,
#'   x = "world",
#'   y = "tera",
#'   outfile = outfile
#' )
#'
#' readLines(outfile, warn = FALSE)
render_template <- function(path, ..., outfile = NULL, autoescape = TRUE) {
  check_string(path)
  check_files_exist(path)
  check_string(outfile, allow_null = TRUE)
  check_bool(autoescape)
  tera <- Tera$new()
  if (!autoescape) {
    tera$autoescape_off()
  }
  template_name <- basename(path)
  tera$add_file_templates(!!!rlang::set_names(path, template_name))
  tera$render_template(template_name, ..., outfile = outfile)
}

#' @rdname render-one-off
#' @export
render_string <- function(string, ..., outfile = NULL, autoescape = TRUE) {
  check_string(string)
  check_string(outfile, allow_null = TRUE)
  check_bool(autoescape)
  tera <- Tera$new()
  if (!autoescape) {
    tera$autoescape_off()
  }
  tera$render_string(string, ..., outfile = outfile)
}
