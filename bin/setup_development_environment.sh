#!/usr/bin/env sh

set -e

SUPERUSER_COMMAND=""

if [ "$(whoami)" != "root" ]; then
  SUPERUSER_COMMAND="sudo"
fi

detect_os() {
  if [ -z "${OSTYPE}" ]; then
    echo "OSTYPE environment variable is not set, cannot continue." 2>&1
  fi

  case "${OSTYPE}" in
  *darwin*)
    printf "%s" "macos"
    ;;
  *linux*)
    printf "%s" "linux"
    ;;
  *)
    printf "%s" "other"
    ;;
  esac
}

# shellcheck disable=SC2120
get_package_manager() {
  os_shorthand="${1:-$(detect_os)}"

  case "${os_shorthand}" in
  macos)
    if ! command -v brew 1 >>/dev/null; then
      echo "Brew could not be found and you're on macOS! Please install homebrew (see https://brew.sh)" 1>&2
      exit 1
    fi
    printf "%s" "brew"
    ;;
  linux)
    if command -v apt-get >>/dev/null; then
      printf "%s" "apt-get"
    elif command -v dnf >>/dev/null; then
      printf "%s" "dnf"
    elif command -v yum >>/dev/null; then
      printf "%s" "yum"
    elif command -v brew >>/dev/null; then
      printf "%s" "brew"
    fi
    ;;
  *)
    echo "OS (${os_shorthand}) not supported!" 1>&2
    exit 1
    ;;
  esac
}

install_hadolint() {
  if [ "$(uname -m)" = "aarch64" ]; then
    arch_code="arm64"
  else
    arch_code="x86_64"
  fi

  if ! command -v hadolint >>/dev/null; then
    download_url="$(curl -s https://api.github.com/repos/hadolint/hadolint/releases/latest | grep Linux | grep browser_download_url | grep -v sha256 | grep "${arch_code}" | awk '{gsub("\"", ""); print $2}')"

    echo "Hadolint download url: ${download_url}" 1>&2

    curl -L -o hadolint-test "${download_url}"
    ${SUPERUSER_COMMAND} mv hadolint-test /usr/local/bin/hadolint
    ${SUPERUSER_COMMAND} chmod +x /usr/local/bin/hadolint
  fi

}

install_tfenv() {
  if ! command -v tfenv >>/dev/null; then
    git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
    ln -s ~/.tfenv/bin/* /usr/local/bin
  fi

  tfenv install latest
}

install_aws_cli() {
  if ! command -v aws >>/dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ${SUPERUSER_COMMAND} ./aws/install
    rm -rf ./aws ./awscliv2.zip
  fi
}

install_kubectl() {
  if [ "$(uname -m)" = "aarch64" ]; then
    arch_code="arm64"
  else
    arch_code="amd64"
  fi

  if ! command -v kubectl >>/dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${arch_code}/kubectl"

    ${SUPERUSER_COMMAND} install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f ./kubectl
  fi
}

install_helm() {
  if ! command -v helm >>/dev/null; then
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    export VERIFY_CHECKSUM=false
    ${SUPERUSER_COMMAND} ./get_helm.sh
    unset VERIFY_CHECKSUM
    rm ./get_helm.sh
  fi
}

install_pyenv() {
  if ! command -v pyenv >>/dev/null; then
    curl https://pyenv.run | bash
  fi

  export PYENV_ROOT="$HOME/.pyenv"
  # shellcheck disable=SC3010
  [ -d $PYENV_ROOT/bin ] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"

  pyenv install -s 3.13.0

  if [ "$(pyenv global)" = "system" ]; then
    pyenv global 3.13.0
  fi
}

install_pre_commit() {
  python3 -m pip install -U pre-commit
}

install_with_brew() {
  brew bundle --no-lock --no-upgrade
}

install_with_apt_get() {
  ${SUPERUSER_COMMAND} apt-get update
  # shellcheck disable=SC2046
  ${SUPERUSER_COMMAND} apt-get install -y --no-install-recommends \
    $(cat ./apt-get_dependencies.txt)

  install_hadolint
  install_tfenv
  install_aws_cli
  install_kubectl
  install_helm
  install_pyenv
  install_pre_commit
}

install_with_dnf() {
  ${SUPERUSER_COMMAND} dnf update -y
  # shellcheck disable=SC2046
  ${SUPERUSER_COMMAND} dnf install -y \
    $(cat ./dnf_dependencies.txt)

  install_hadolint
  install_tfenv
  install_aws_cli
  install_kubectl
  install_helm
  install_pyenv
  install_pre_commit
}

main() {
  os="$(detect_os)"
  package_manager="$(get_package_manager "${os}")"

  echo "Your os type: ${os}"
  echo "Your package manager: ${package_manager}"

  # shellcheck disable=SC2091
  $(echo "install_with_${package_manager}" | awk '{gsub("-", "_"); print $0;}')

  echo "Installations complete, make sure to add any necessary changes to shell configurations as needed."
}

# shellcheck disable=SC2068
main ${@}
