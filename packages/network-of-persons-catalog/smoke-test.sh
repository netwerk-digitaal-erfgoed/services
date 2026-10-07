#!/usr/bin/env bash
#
# Starts a built image and checks that it serves the catalogue: the response to a request must name
# the dataset. Run after the image’s docker:build.
#
# Usage: smoke-test.sh <image> <path> [<curl argument>...]
set -euo pipefail

image=$1
path=$2
shift 2

dataset='https://data.niod.nl/WO2_personen'

container=$(docker run --detach --rm --publish 127.0.0.1::3123 "$image")
trap 'docker stop "$container" > /dev/null' EXIT
address=$(docker port "$container" 3123)

# The server needs a few seconds to load the catalogue before it answers.
response=$(curl --silent --show-error --fail --retry 30 --retry-delay 2 --retry-all-errors "$@" "http://$address$path")

if [[ "$response" != *"$dataset"* ]]; then
  echo "$image does not serve $dataset. It answered: $response" >&2
  exit 1
fi

echo "$image serves $dataset."
