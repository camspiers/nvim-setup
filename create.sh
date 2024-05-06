#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script's directory
cd "$SCRIPT_DIR" || exit

# Check if docker command exists
if command -v podman &>/dev/null; then
	CONTAINER_TOOL="podman"
# Check if podman command exists
elif command -v docker &>/dev/null; then
	CONTAINER_TOOL="docker"
# If neither docker nor podman is found
else
	echo "Neither Docker nor Podman is installed." >&2
	exit 1
fi

$CONTAINER_TOOL build -t $1 --build-arg "NVIM_CONFIG_URL=$2" .
$CONTAINER_TOOL volume rm --force $1
$CONTAINER_TOOL volume create $1

# Add nvim alias to bashrc
cat <<EOF | tee -a ~/.bashrc

function $1 () {
  rm -f /tmp/container_id_$1
  $CONTAINER_TOOL run --cidfile /tmp/container_id_$1 -v $1:/root/.local -v .:/root/dev -it $1 "\$@"
  echo "Committing changes to docker container:"
  $CONTAINER_TOOL container commit \$(cat /tmp/container_id_$1) $1
}
EOF