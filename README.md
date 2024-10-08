# Wordpress on EKS

Demo to get wordpress running on EKS in AWS using Terraform, Containers & more.

## Getting started

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
