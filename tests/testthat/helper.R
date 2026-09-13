# path to templates directory in package directory
template_dir <- function() {
  system.file("templates", package = "tera")
}

# path to a template file in package directory
template <- function(...) {
  file.path(template_dir(), ...)
}

# read lines from file, suppress 'incomplete final line' warning
read <- function(path) {
  readLines(path, warn = FALSE)
}
