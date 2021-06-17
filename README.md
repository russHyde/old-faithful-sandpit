# Old-faithful

This is a sandpit app, to demonstrate how to add CI/CD using GHA and shinyapps.io

# Deployment to shinyapps-io on push

Workflow `./.github/workflows/shinyapps-io.yaml` is used to deploy to shinyapps.io

## Github secrets

To use the deploy workflow, you must define some values as github-secrets in your repository.
Github secrets are a way to store values that shouldn't be shared in your repository (eg, api keys
for hosting sites, database access keys).

The required values are:

- Secrets regarding your shinyapps.io account:
  - `SHINYAPPS_IO_ACCOUNT`
  - `SHINYAPPS_IO_TOKEN`
  - `SHINYAPPS_IO_SECRET`

- Secrets that are used during the running of the app (these are put into .Renviron prior to
  deployment)
  - `NOT_MY_API_KEY`

To get theshinyapps.io values, go to [https://www.shinyapps.io/admin/#/tokens]() and click "show"
on your shinyapps.io token.
A modal will show up that looks like:

```
    rsconnect::setAccountInfo(name='<MY-ACCOUNT-NAME>',
                              token='<MY-TOKEN>',
                              secret='<SECRET>')
```

Make sure you do not share the "<SECRET>" value with anyone.

To add values as github secrets to a repository on github:

- GOTO: [repo] -> settings -> secrets
- Click "New repository secret"
- Add the name of the relevant secret (eg, `SHINYAPPS_IO_ACCOUNT`, `SHINYAPPS_IO_TOKEN`, ...) into
  the "Name" field
- Add the value of the relevant secret to the "Value field"

You will be taken back to the "secrets" section of the github repository where the names of all
your currently-defined github-secrets are shown.

## Github action

Branches get deployed to: `<URL_PREFIX>-<branch-name>`
Merges into main get deployed to: `<URL_PREFIX>`

.. where `URL_PREFIX` is the main site.
