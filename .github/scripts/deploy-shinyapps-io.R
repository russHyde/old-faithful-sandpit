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

get_app_name = function() {
  branch_name = get_branch_name()
  app_basename = Sys.getenv("APP_BASENAME", get_repo_name())
  app_name = if (branch_name %in% c("master", "main")) {
    app_basename
  } else {
    paste(app_basename, branch_name, sep = "-")
  }
  app_name
}

deploy = function(account = "jumpingrivers", server = "shinyapps.io") {
  cli::cli_h1("Deploying app")
  rsconnect::setAccountInfo(
    name = account,
    token = Sys.getenv("SHINYAPPS_IO_TOKEN"),
    secret = Sys.getenv("SHINYAPPS_IO_SECRET")
  )

  app_name = get_app_name()

  cli::cli_alert_info("appName: ", app_name)

  rsconnect::deployApp(
    account = account,
    server = server,
    appName = app_name,
    appDir = "."
  )

  cli::cli_alert_success("{app_name} successfully deployed")
}

# Clean up (eg, after merging / closing a branch).
terminate = function(account = "jumpingrivers", server = "shinyapps.io") {
  cli::cli_h1("Terminating app")
  rsconnect::setAccountInfo(
    name = account,
    token = Sys.getenv("SHINYAPPS_IO_TOKEN"),
    secret = Sys.getenv("SHINYAPPS_IO_SECRET")
  )

  app_name = get_app_name()

  rsconnect::terminateApp(
    account = account,
    server = server,
    appName = app_name
  )
  cli::cli_alert_success("{app_name} successfully terminated")
}

configure = function(account = "jumpingrivers", server = "shinyapps.io", size = "large") {
  rsconnect::setAccountInfo(
    name = account,
    token = Sys.getenv("SHINYAPPS_IO_TOKEN"),
    secret = Sys.getenv("SHINYAPPS_IO_SECRET")
  )

  app_name = get_app_name()

  rsconnect::configureApp(
    account = account,
    server = server,
    appName = app_name,
    size = size
  )
  cli::cli_alert_success("{app_name} successfully configured")
}

# user should call the appropriate functions in GHA recipe
# eg, deploy(account = my_account)
