# convert dots to context json string
dots_to_json <- function(..., call = rlang::caller_call()) {
  context <- rlang::list2(...)
  check_list_named(context, call = call)
  if (length(context) == 0L) {
    return("{}")
  }
  yyjsonr::write_json_str(context, auto_unbox = TRUE)
}

# catch an error condition thrown or returned by extendr and re-signal it
# against the public method the user actually called
.catch <- function(expr, call = rlang::caller_call()) {
  rlang::try_fetch(
    expr,
    error = function(cnd) cli::cli_abort(cnd[["message"]], call = call)
  )
}

# ensure a list contains only named elements
check_list_named <- function(dots, call = rlang::caller_call()) {
  if (!rlang::is_named2(dots)) {
    cli::cli_abort(
      "All arguments provided to {.arg ...} must be named",
      call = call
    )
  }
  invisible(dots)
}

# check if template files exist
check_files_exist <- function(files, call = rlang::caller_call()) {
  missing <- files[!file.exists(unlist(files))]
  if (rlang::has_length(missing)) {
    n_missing <- cli::qty(length(missing))
    cli::cli_abort(
      "Could not find {n_missing} template{?s} at {.file {missing}}.",
      call = call
    )
  }
  invisible(files)
}
