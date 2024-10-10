#!/usr/bin/env sh

set -e

get_container_command() {
  if command -v podman >>/dev/null; then
    printf "%s" "podman"
  elif command -v docker >>/dev/null; then
    printf "%s" "docker"
  else
    echo "No supported container CLI/manager was found" 1>&2
    exit 1
  fi
}

main() {
  target_distro="${1:-ubuntu}"

  container_name="wordpress-on-eks-dev-container-${target_distro}"
  container_command="$(get_container_command)"
  the_tag="wordpress-on-eks:${target_distro}-dev"

  ${container_command} build \
    -t "${the_tag}" \
    --target "${target_distro}-base" \
    -f Containerfile.dev

  ${container_command} run \
    -it \
    --rm \
    -d \
    --name "${container_name}" \
    -v ~/.aws:/root/.aws \
    -v "$(pwd)":/workdir \
    "${the_tag}"

  ${container_command} exec \
    -it \
    "${container_name}" \
    direnv allow

  ${container_command} exec \
    -it \
    "${container_name}" \
    tfenv install

  set +e
  ${container_command} exec \
    -it \
    "${container_name}" \
    /bin/zsh

  echo "Stopping container"
  "${container_command}" stop \
    "${container_name}"
  set -e
}

# shellcheck disable=SC2068
main ${@}
