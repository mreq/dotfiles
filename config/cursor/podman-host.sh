#!/bin/bash
# Forward a docker-CLI-compatible podman invocation to the host.
# Used as dev.containers.dockerPath so Cursor (running inside the apps
# distrobox) can drive the host's rootless podman for Dev Containers.
exec distrobox-host-exec podman "$@"
