#!/bin/bash
# Wrapper used as podman's compose_providers entry.
# --in-pod=0 disables grouping services into a pod, which otherwise conflicts
# with --userns=keep-id that Dev Containers sets on the primary service.
exec /usr/bin/podman-compose --in-pod=0 "$@"
