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

IMAGE_NAME="nvim-setup-$1"
EXECUTABLE_PATH="/usr/local/bin/$1"
CONTAINER_ID_PATH="/tmp/container-id-$IMAGE_NAME"

# Build the image and name it $1
$CONTAINER_TOOL build -t $IMAGE_NAME --build-arg "NVIM_CONFIG_URL=$2" .

# Force remove any existing volumes
$CONTAINER_TOOL volume rm --force $IMAGE_NAME

if [ -e $EXECUTABLE_PATH ]; then
	# File exists, prompt the user if they want to overwrite it
	read -p "File '$EXECUTABLE_PATH' already exists. Do you want to overwrite it? (y/n): " answer
	if [ "$answer" != "y" ]; then
		echo "Aborted. File not overwritten."
		exit 0
	fi
fi

# Add nvim alias to bashrc
cat <<EOF | sudo tee $EXECUTABLE_PATH >/dev/null
#!/bin/bash

rm -f $CONTAINER_ID_PATH
$CONTAINER_TOOL volume create $IMAGE_NAME
$CONTAINER_TOOL run \
  --cidfile $CONTAINER_ID_PATH \
  -v $IMAGE_NAME:/root/.local \
  -v .:/root/dev \
  -v ~/.gitconfig:/root/.gitconfig \
  -it \
  $IMAGE_NAME \
  "\$@"

echo "Committing changes to docker container:"

$CONTAINER_TOOL container commit \
  \$(cat $CONTAINER_ID_PATH) $IMAGE_NAME
EOF

sudo chmod +x $EXECUTABLE_PATH
