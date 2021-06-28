## Needs suggests for rsconnect to deploy
install_script_deps = function() {
  install.packages("rsconnect", dependencies = TRUE)
  if (!requireNamespace("stringr", quietly = TRUE)) install.packages("stringr")
  if (!requireNamespace("cli", quietly = TRUE)) install.packages("cli")
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
}

# Needs the following secrets:
# github.com/username/repo -> Settings -> Secrets
# SHINYAPPS_IO_TOKEN
# SHINYAPPS_IO_SECRET


# message(Sys.getenv('GITHUB_REPOSITORY'))
# message(Sys.getenv("GITHUB_REF"))
# message(Sys.getenv("COMMIT_MESSAGE"))

# This function would be used if the Shiny app was a package
# Self install from the branch, then deploy
# install_pkg = function() {
#   cli::cli_h1("Install pkg")
#   path = paste(Sys.getenv('GITHUB_REPOSITORY'), Sys.getenv("GITHUB_REF"), sep = "@")
#   cli::cli_alert_info("Installing {path}")
#   remotes::install_github(path, upgrade = "never")
#   cli::cli_alert_success("{path} installed!")
# }
#

get_branch_name = function() {
  # If your branch is called "add-new-thing"
  # Then,
  # In an on-PR workflow
  #  - the GITHUB_REF is "refs/pull/<number>/merge"
  #  - the GITHUB_HEAD_REF is "add-new-thing"
  # In an on-push workflow
  #  - the GITHUB_REF is "refs/head/add-new-thing"
  #  - and the GITHUB_HEAD_REF is undefined

  # Use the PR head-branch name if event is a PR
  head_ref = Sys.getenv("GITHUB_HEAD_REF")
  if (head_ref != "") {
    return(head_ref)
  }

  # Use the branch containing the commit if event is a push
  branch_name = stringr::str_match(Sys.getenv("GITHUB_REF"), "^refs/heads/(.*)$")[1, 2]
  branch_name
}

get_repo_name = function() {
  repo_name = stringr::str_match(Sys.getenv("GITHUB_REPOSITORY"), ".*/(.*)$")[1, 2]
  repo_name
}

get_app_name = function(include_branch) {
  app_basename = Sys.getenv("APP_BASENAME", get_repo_name())
  if (!include_branch) {
    return(app_basename)
  }

  app_name = if (get_branch_name() %in% c("master", "main")) {
    app_basename
  } else {
    app_suffix = paste0("-", get_branch_name())
    paste0(app_basename, app_suffix)
  }
  app_name
}


#' Set up context within which to deploy / configure / terminate an app
#'
#' The ENV variables "SHINYAPPS_IO_ACCOUNT", "SHINYAPPS_IO_TOKEN", "SHINYAPPS_IO_SECRET" should
#' all be available
setup = function() {
  rsconnect::setAccountInfo(
    name = Sys.getenv("SHINYAPPS_IO_ACCOUNT", "jumpingrivers"),
    token = Sys.getenv("SHINYAPPS_IO_TOKEN"),
    secret = Sys.getenv("SHINYAPPS_IO_SECRET")
  )
}

#' To deploy, configure or terminate an app at shinyapps.io, you first need to add a user account
#' to the local machine. Here we add the user account (based on env variables
#' SHINYAPPS_IO_[ACCOUNT|TOKEN|SECRET] then run one of the rsconnect functions).
#'
#' @param   f   An rsconnect function, typically deployApp, terminateApp, configureApp.
#' @param   ...   Arguments for the rsconnect function (except AppName, which we determine based on
#' ENV variable APP_BASENAME and the current branch)
#' @param   include_branch   Should the branch name be appended to the name of the app during
#' deployment?
#' @param   completion_string   A message to be printed when the function completes
#' "<app_name>: <completion_string>".
#' @return   NULL

setup_and_run = function(f, ..., include_branch = TRUE, completion_string = "") {
  setup()
  app_name = get_app_name(include_branch = include_branch)

  f(appName = app_name, ...)

  cli::cli_alert_info(paste0(app_name, ": ", completion_string))
}

###################################################################################################

# Functions for calling by the user

deploy = function(
    account = "jumpingrivers",
    server = "shinyapps.io",
    include_branch = TRUE,
    ...
) {
  cli::cli_h1("Deploying app")

  setup_and_run(
    rsconnect::deployApp,
    account = account,
    server = server,
    ...,
    include_branch = include_branch,
    completion_string = "successfully deployed"
  )
}

# Clean up (eg, after merging / closing a branch).
terminate = function(
    account = "jumpingrivers",
    server = "shinyapps.io",
    include_branch = TRUE
) {
  cli::cli_h1("Terminating app")

  setup_and_run(
    rsconnect::terminateApp,
    account = account,
    server = server,
    include_branch = include_branch,
    completion_string = "successfully terminated"
  )
}

configure = function(
    account = "jumpingrivers",
    server = "shinyapps.io",
    size = "large",
    include_branch = TRUE
) {
  setup_and_run(
    rsconnect::configureApp,
    account = account,
    server = server,
    size = size,
    include_branch = include_branch,
    completion_string = "successfully configured"
  )
}

###################################################################################################

# User should `source()` this script, then call the appropriate functions in GHA recipe
# eg, deploy(account = my_account)
#
# Make sure you've called `install_script_deps()`, or the dependencies for the functions won't be
# available
