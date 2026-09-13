#' R6 class for Tera templating engine
#'
#' A Tera templating engine for rendering templates with contexts consisting of
#' variables and values. Similar to glue, but with additional template logic.
#'
#' @details
#' The glob pattern `templates/*.html` will match all files with the .html
#' extension located directly inside the `templates` folder, while
#' `templates/**/*.html` will match all files with the .html extension
#' directly inside or in a subdirectory of `templates`. The default naming
#' convention is to give each template their full relative path from
#' `templates` (or whatever the template directory is called).
#'
#' When initialized with a glob, template names take the path of the file
#' template relative to the base of the template directory. For example, if you
#' pass `templates/**/*.html`, the template file `templates/blog/post.html`
#' would have the name `blog/post.html`. When specified manually, all templates
#' must be named. The same is true of context variables.
#'
#' It is possible to add variables to a global context that can be accessed in
#' any template. See the `set_globals()` method.
#'
#' @export
#'
#' @examples
#' # - setup -----
#' # initialize empty Tera engine
#' tera <- Tera$new()
#' tera
#'
#' # initialize Tera engine from directory with glob
#' template_dir <- system.file("templates", package = "tera")
#' glob <- "**/*.html"
#' tera <- Tera$new(file.path(template_dir, glob))
#' tera
#'
#' # add templates manually from file
#' tera <- Tera$new()
#' tera$add_file_templates(
#'   "base.html" = file.path(template_dir, "base.html"),
#'   "index.html" = file.path(template_dir, "index.html")
#' )
#' tera
#'
#' # add templates manually from string
#' tera$add_string_templates(
#'   img = '<img src="{{ img_src }}">'
#' )
#' tera
#'
#' # reload templates from glob
#' example_dir <- file.path(tempdir(), "tera-templates")
#' dir.create(example_dir)
#'
#' file.copy(
#'   from = file.path(template_dir, "base.html"),
#'   to = file.path(example_dir, "base.html")
#' )
#'
#' tera <- Tera$new(file.path(example_dir, "*.html"))
#' tera
#'
#' file.copy(
#'   from = file.path(template_dir, "index.html"),
#'   to = file.path(example_dir, "index.html")
#' )
#'
#' tera$reload()
#'
#' # - rendering -----
#' tera <- Tera$new(file.path(template_dir, glob))
#'
#' cat(
#'   readLines(file.path(template_dir, "index.html")),
#'   sep = "\n"
#' )
#'
#' # render a template file
#' tera$render_template(
#'   "index.html",
#'   title = "Index",
#'   p = "Welcome to my awesome homepage.",
#'   owner = "Blake"
#' )
#'
#' # render a template block
#' tera$render_template(
#'   "index.html",
#'   title = "Index",
#'   p = "Welcome to my awesome homepage.",
#'   owner = "Bob",
#'   block = "content"
#' )
#'
#' # render a template string
#' tera$render_string(
#'   '<img src="{{ img_src }}">',
#'   img_src = "foo/bar.svg"
#' )
#'
#' # render a component
#' cat(
#'   readLines(file.path(template_dir, "components.html")),
#'   sep = "\n"
#' )
#'
#' tera$render_component(
#'   "button",
#'   label = "Primary Button",
#'   variant = "primary"
#' )
#'
#' # render a component with body
#' tera$render_component(
#'   "widget",
#'   title = "foo",
#'   body = "<p>This is a widget!</p>"
#' )
#'
#' # - inspection -----
#' # list all templates in library
#' tera$templates()
#'
#' # list all variables in template
#' tera$variables("index.html")
#'
#' # list all components in library
#' tera$components()
#'
#' # - global context -----
#' # add variables to global context
#' tera$set_globals(
#'   base_url = "https://www.example.com",
#'   site_title = "My Website",
#'   description = "This is my awesome website!"
#' )
#'
#' # list all variables in global context
#' tera$globals()
#'
#' # clear global context
#' tera$clear_globals()
#' tera$globals()
#'
#' # - autoescape -----
#' tera <- Tera$new()
#'
#' template_dir <- system.file("templates", package = "tera")
#' tera$add_file_templates(
#'   "hello" = file.path(template_dir, "hello.html"),
#'   "hello.html" = file.path(template_dir, "hello.html")
#' )
#'
#' # not recognized as html
#' tera$render_to_string(
#'   "hello",
#'   x = "&world",
#'   y = "an apostrophe, '"
#' )
#'
#' # html
#' tera$render_to_string(
#'   "hello.html",
#'   x = "&world",
#'   y = "an apostrophe, '"
#' )
#'
#' # turn off autoescape
#' tera$autoescape_off()
#'
#' tera$render_to_string(
#'   "hello.html",
#'   x = "&world",
#'   y = "an apostrophe, '"
#' )
#'
#' # - delimiters -----
#' # must be set before any templates are added
#' tera <- Tera$new()
#'
#' tera$set_delimiters(
#'   variable_start = "<<",
#'   variable_end = ">>"
#' )
#'
#' tera$delimiters()
#'
#' tera$render_string("<< greeting >>, world!", greeting = "Hello")
Tera <- R6::R6Class(
  "Tera",
  private = list(
    extendr = NA,
    .globals = list(),
    .autoescape = TRUE,
    .delimiters = list(
      block_start = "{%",
      block_end = "%}",
      variable_start = "{{",
      variable_end = "}}",
      comment_start = "{#",
      comment_end = "#}"
    )
  ),
  public = list(
    #' @description
    #' Initialize a Tera template engine
    #'
    #' @param glob character scalar, a glob pattern with `*` wildcards
    #'   indicating a potentially nested directory containing multiple file
    #'   templates. If `NULL` (the default), a `Tera` engine with an empty
    #'   library is initialized.
    #'
    #' @returns an R6 `Tera` template engine.
    initialize = function(glob = NULL) {
      check_string(glob, allow_null = TRUE)

      if (rlang::is_null(glob)) {
        private$extendr <- .catch(RTera$new())
      } else {
        private$extendr <- .catch(RTera$new_from_glob(glob))
      }

      invisible(self)
    },

    #' @description
    #' Print Tera
    #'
    #' @param n integer scalar, number of templates to print (default is 10L)
    #' @param ... ignored
    #'
    #' @returns Self (invisibly)
    print = function(n = 10L, ...) {
      check_number_whole(n)

      template_library <- .catch(private$extendr$get_templates()) |> sort()
      if (length(template_library) > n) {
        template_library <- c(head(template_library, n), "...")
      }

      n_global_variables <- length(private$.globals)
      n_components <- length(.catch(private$extendr$get_components()))
      d <- private$.delimiters
      d_blk <- paste0(d[["block_start"]], " Block ", d[["block_end"]])
      d_var <- paste0(d[["variable_start"]], " Variable ", d[["variable_end"]])
      d_com <- paste0(d[["comment_start"]], " Comment ", d[["comment_end"]])

      remove_vertical_space <- list(
        h2 = list("margin-top" = 0, "margin-bottom" = 0)
      )

      cli::cli_div(theme = remove_vertical_space)
      cli::cli_h2("Tera")
      cli::cli_text("Template library:")
      cli::cli_ul(template_library)
      cli::cli_text("")
      cli::cli_text(sprintf("Globals: %s", n_global_variables))
      cli::cli_text(sprintf("Components: %s", n_components))
      cli::cli_text(sprintf("Autoescape: %s", private$.autoescape))
      cli::cli_text(sprintf("Delimiters: %s, %s, %s", d_blk, d_var, d_com))
      cli::cli_end()

      invisible(self)
    },

    #' @description
    #' Add file templates to library from file paths.
    #'
    #' @param ... specify list of templates as `key = value` pairs where key is
    #'   the name of the template and value is the path to the template on file.
    #'
    #' @returns Self (invisibly)
    add_file_templates = function(...) {
      templates <- rlang::list2(...)
      check_files_exist(templates)
      check_list_named(templates)
      .catch(private$extendr$add_file_templates(templates))
      invisible(self)
    },

    #' @description
    #' Add templates to library from character strings.
    #'
    #' @param ... specify list of templates as `key = value` pairs where key is
    #'   the name of the template and value is a string template.
    #'
    #' @returns Self (invisibly)
    add_string_templates = function(...) {
      templates <- rlang::list2(...)
      check_list_named(templates)
      .catch(private$extendr$add_string_templates(templates))
      invisible(self)
    },

    #' @description
    #' Re-parse all file templates found in the glob given to Tera, including
    #' any new file templates that were added. Templates added manually are
    #' preserved.
    #'
    #' @returns Self (invisibly)
    reload = function() {
      .catch(private$extendr$full_reload())
      invisible(self)
    },

    #' @description
    #' Render specified template file to string or file if `outfile` is
    #' specified.
    #'
    #' @param template character scalar, the name of the template to render.
    #' @param ... specify context as `key = value` pairs where key is the
    #'   template variable and value is the data to inject.
    #' @param block character scalar, if not `NULL`, interpolation will be
    #'   restricted to the specified block in template (default is `NULL`).
    #' @param outfile character scalar, the path to file where template is to
    #'   be rendered (default is `NULL`).
    #'
    #' @returns if `outfile = NULL` (default), the rendered string; otherwise,
    #'   `outfile` (invisibly).
    render_template = function(template, ..., block = NULL, outfile = NULL) {
      check_string(template)
      check_string(outfile, allow_null = TRUE)
      context_string <- dots_to_json(...)
      if (rlang::is_null(block)) {
        if (rlang::is_null(outfile)) {
          .catch(private$extendr$render_template_to_string(
            template,
            context_string
          ))
        } else {
          .catch(private$extendr$render_template_to_file(
            template,
            context_string,
            outfile
          ))
          invisible(outfile)
        }
      } else {
        if (rlang::is_null(outfile)) {
          .catch(private$extendr$render_block_to_string(
            template,
            block,
            context_string
          ))
        } else {
          .catch(private$extendr$render_block_to_file(
            template,
            block,
            context_string,
            outfile
          ))
          invisible(outfile)
        }
      }
    },

    #' @description
    #' Render specified template string to string or file if `outfile` is
    #' specified.
    #'
    #' @param string character scalar, the template string to render.
    #' @param ... specify context as `key = value` pairs where key is the
    #'   template variable and value is the data to inject.
    #' @param outfile character scalar, the path to file where template is to
    #'   be rendered (default is `NULL`).
    #' @param autoescape boolean scalar, whether to autoescape HTML (default is
    #'   `TRUE`).
    #'
    #' @returns if `outfile = NULL` (default), the rendered string; otherwise,
    #'   `outfile` (invisibly).
    render_string = function(string, ..., outfile = NULL, autoescape = TRUE) {
      check_string(string)
      check_string(outfile, allow_null = TRUE)
      check_bool(autoescape)
      context_string <- dots_to_json(...)
      if (rlang::is_null(outfile)) {
        .catch(private$extendr$render_string_to_string(
          string,
          context_string,
          autoescape
        ))
      } else {
        .catch(private$extendr$render_string_to_file(
          string,
          context_string,
          autoescape,
          outfile
        ))
        invisible(outfile)
      }
    },

    #' @description
    #' Render specified component to string or file if `outfile` is specified.
    #'
    #' @param component character scalar, the name of the component to render.
    #' @param ... specify context as `key = value` pairs where key is the
    #'   template variable and value is the data to inject.
    #' @param body character scalar, optional, passed to component `{{ body }}`
    #'   variable.
    #' @param outfile character scalar, the path to file where template is to
    #'   be rendered (default is `NULL`).
    #' @param autoescape boolean scalar, whether to autoescape HTML (default is
    #'   `TRUE`).
    #'
    #' @returns if `outfile = NULL` (default), the rendered string; otherwise,
    #'   `outfile` (invisibly).
    render_component = function(
      component,
      ...,
      body = NULL,
      outfile = NULL,
      autoescape = TRUE
    ) {
      check_string(component)
      check_string(body, allow_null = TRUE)
      check_string(outfile, allow_null = TRUE)
      check_bool(autoescape)
      context_string <- dots_to_json(...)
      if (rlang::is_null(outfile)) {
        .catch(private$extendr$render_component_to_string(
          component,
          context_string,
          body,
          autoescape
        ))
      } else {
        .catch(private$extendr$render_component_to_file(
          component,
          context_string,
          body,
          autoescape,
          outfile
        ))
        invisible(outfile)
      }
    },

    #' @description
    #' List current templates in library.
    #'
    #' @returns a sorted `character` vector of template names
    templates = function() {
      .catch(private$extendr$get_templates()) |> sort()
    },

    #' @description
    #' List current components in library.
    #'
    #' @returns a sorted `character` vector of component names
    components = function() {
      .catch(private$extendr$get_components()) |> sort()
    },

    #' @description
    #' List all variables in template.
    #'
    #' @param template character scalar, the name of the template.
    #'
    #' @returns a sorted `character` vector of variable names
    variables = function(template) {
      .catch(private$extendr$get_variables(template)) |> sort()
    },

    #' @description
    #' Turn on autoescaping of HTML. This only applies to templates whose names
    #' end with ".html", ".htm", or ".xml". Autoescaping is on by default.
    #'
    #' @returns Self (invisibly)
    autoescape_on = function() {
      .catch(private$extendr$autoescape_on())
      private$.autoescape <- TRUE
      invisible(self)
    },

    #' @description
    #' Turn off autoescaping of HTML. This only applies to templates whose names
    #' end with ".html", ".htm", or ".xml". Autoescaping is on by default.
    #'
    #' @returns Self (invisibly)
    autoescape_off = function() {
      .catch(private$extendr$autoescape_off())
      private$.autoescape <- FALSE
      invisible(self)
    },

    #' @description
    #' Add a set of variables to a global context that can then be accessed by
    #' every template. If a variable with the same name already exists, it is
    #' overridden.
    #'
    #' @param ... specify context as `key = value` pairs where key is the
    #'   template variable and value is the data to inject.
    #'
    #' @returns Self (invisibly)
    set_globals = function(...) {
      globals <- rlang::list2(...)
      check_list_named(globals)
      private$.globals[names(globals)] <- globals
      globals_string <- yyjsonr::write_json_str(
        private$.globals,
        auto_unbox = TRUE
      )
      .catch(private$extendr$set_globals(globals_string))
      invisible(self)
    },

    #' @description
    #' List current variables in global context.
    #'
    #' @returns a sorted `character` vector of variable names
    globals = function() {
      names(private$.globals) |> sort()
    },

    #' @description
    #' Remove all variables from global context. Resets to an empty context.
    #'
    #' @returns Self (invisibly)
    clear_globals = function() {
      .catch(private$extendr$clear_globals())
      private$.globals <- list()
      invisible(self)
    },

    #' @description
    #' Set the delimiters used to mark up templates, which is useful for
    #' templating files that themselves contain `{{`, such as LaTeX. Each
    #' delimiter must be exactly two bytes long, the three start delimiters must
    #' differ from each other, and any delimiter left `NULL` is unchanged.
    #'
    #' Delimiters must be set before any templates are added, so this can only
    #' be called on an engine with an empty library.
    #'
    #' @param block_start,block_end character scalar, delimiters for blocks and
    #'   statements (defaults are `"{%"` and `"%}"`).
    #' @param variable_start,variable_end character scalar, delimiters for
    #'   variables (defaults are `"{{"` and `"}}"`).
    #' @param comment_start,comment_end character scalar, delimiters for
    #'   comments (defaults are `"{#"` and `"#}"`).
    #'
    #' @returns Self (invisibly)
    set_delimiters = function(
      block_start = NULL,
      block_end = NULL,
      variable_start = NULL,
      variable_end = NULL,
      comment_start = NULL,
      comment_end = NULL
    ) {
      check_string(block_start, allow_null = TRUE)
      check_string(block_end, allow_null = TRUE)
      check_string(variable_start, allow_null = TRUE)
      check_string(variable_end, allow_null = TRUE)
      check_string(comment_start, allow_null = TRUE)
      check_string(comment_end, allow_null = TRUE)

      new <- list(
        block_start = block_start,
        block_end = block_end,
        variable_start = variable_start,
        variable_end = variable_end,
        comment_start = comment_start,
        comment_end = comment_end
      )
      new <- Filter(length, new)

      delimiters <- private$.delimiters
      delimiters[names(new)] <- new

      .catch(private$extendr$set_delimiters(delimiters))
      private$.delimiters <- delimiters
      invisible(self)
    },

    #' @description
    #' List the delimiters currently used to mark up templates.
    #'
    #' @returns a named `list` of delimiters
    delimiters = function() {
      private$.delimiters
    }
  ),
  cloneable = FALSE
)
