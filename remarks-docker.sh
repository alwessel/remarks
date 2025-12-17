#!/bin/bash
#
# The script build remarks as docker image if not yet existing and execute it
# in order to extract the annotations from remarkable files.
#
# <arg1> - directory with the remarkable files (required)
# <arg2> - output directory with annotations (required)
#  flag:
# --ssh-sync-before - if given the  then rsync is used to download the files before processing
set -eu

if [ "${1:-}" = "--ssh-sync-before" ]; then
  SSH_SYNC_BEFORE=true
  shift
fi

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 [--ssh-sync-before] <remarkable_files_dir> <output_dir> [-- <remarks args>]" >&2
  exit 1
fi

REMARKABLE_FILES_DIR=$1
OUTPUT_DIR=$2
shift 2

# build image only if it doesn't exist
DOCKER_IMAGE_NAME=remarks
if ! docker image inspect "$DOCKER_IMAGE_NAME" > /dev/null 2>&1; then
  docker build . -f Dockerfile -t "$DOCKER_IMAGE_NAME"
fi

#  perform rsync from device using ssh if requested
if [ -n "${SSH_SYNC_BEFORE:-}" ]; then
  if [ -z "$REMARKABLE_SSH_IP" ] || [ -z "$REMARKABLE_SSH_PW" ]; then
    echo "REMARKABLE_SSH_IP and REMARKABLE_SSH_PW must be set when using --ssh-sync-before" >&2
    exit 2
  fi
  echo "Syncing files from $REMARKABLE_SSH_IP to $REMARKABLE_FILES_DIR..."
  mkdir -p "$REMARKABLE_FILES_DIR"
  echo "   MAKE SURE the remarkable device is not sleeping and that SSH is enabled!"
  RSYNC_CMD="sshpass -p $REMARKABLE_SSH_PW rsync --progress -azh -e \"ssh -o StrictHostKeyChecking=no\" root@$REMARKABLE_SSH_IP:/home/root/.local/share/remarkable/xochitl/ /data"
  docker run --rm -v "$REMARKABLE_FILES_DIR:/data" --entrypoint /bin/bash $DOCKER_IMAGE_NAME -c "$RSYNC_CMD"
fi

echo "Processing files from $REMARKABLE_FILES_DIR to $OUTPUT_DIR..."
docker run --rm -v "$REMARKABLE_FILES_DIR:/input:ro" -v "$OUTPUT_DIR:/output" "$DOCKER_IMAGE_NAME" /input /output "$@"
echo "done."