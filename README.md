# Wordpress on EKS

Demo to get wordpress running on EKS in AWS using Terraform, Containers & more.

## Getting started / development environment

To get started, you will need to install the necessary tooling to deploy to AWS and [create an AWS account](https://aws.amazon.com/resources/create-account/).

### Installing development tools

### macOS

> Make sure you have [Homebrew](https://brew.sh) installed.

To simplify setting up your development environment, please run the following in a bourne-type shell:

```shell
./bin/setup_development_environment.sh
```

### GNU/Linux (Debian-based or RHEL-based or distribution with Homebrew)

> Make sure you have `apt-get` (Debian-based), `dnf`/`yum` (RHEL-based) or `Homebrew`.

To simplify setting up your development environment, please run the following in a bourne-type shell:

```shell
./bin/setup_development_environment.sh
```

### Windows

This project is tailored towards UNIX or GNU/Linux based Operating System (OS). If you're on Windows, please use [WSL (2)](https://learn.microsoft.com/en-us/windows/wsl/install) to work in a GNU/Linux distribution.

#### Developing in a container (`podman`/`docker`)

If you have `Podman` or `Docker` installed, you can work in a "predefined" development environment by building and launching a container image.

To build the container (ubuntu based by default) and launch it, use the following.

```shell
./bin/build_and_run_dev_container.sh
```

## Linting

We use the `pre-commit` framework to audit/lint this codebase. To run it manually, make sure to stage your changes (`git add`) and run `pre-commit run -a` (you may need to add a `python -m` in the front of that command if installed on Linux)

---

## Understanding IaC/Terraform

### Structure

All of our infrastructure as code (IaC)/terraform configurations are listed under `infra`. Under that folder you'll see the following:

- `infra/live/<aws account name>/<component name>`
  - These folders contain the "root" terraform modules where you actually run plan/apply.
- `infra/modules/<module name>`
  - These folders contain custom reusable terraform modules.

### How to run

#### State resources

To get started, you'll need to deploy `state` (also known as "backend") resources, in order to multiple people to work on Terraform together!

```shell
cd infra/live/example-account/state
tfenv install
terraform init
terraform apply
```

> If you renamed the `example-account` directory to your actual account name, keep that in mind later as your state bucket and DynamoDB table name are based off of it!

#### Environment Resources

Next you'll need to deploy platform environment resources! These constitute shared networking and cluster resources for an "environment". Let's start with `dev`.

```shell
cd infra/live/example-account/environments/dev/platform
tfenv install
terraform init
terraform apply
```
