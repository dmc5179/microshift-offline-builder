#!/bin/bash -xe

OCP_RELEASE=4.18.2

EDGE_CONTAINER_NAME=microshift-build

# Get current directory of script, not PWD
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PULL_SECRET=${SCRIPT_DIR}/pull-secret.json
RELEASE_FILE=/usr/share/microshift/release/release-$(uname -m).json
BLUEPRINT_TEMPLATE=${SCRIPT_DIR}/microshift-blueprint-v0.0.1.toml.template
BLUEPRINT_FILE=${SCRIPT_DIR}/microshift-blueprint-v0.0.1.toml

# May need to configure subscription-manager
#subscription-manager config --rhsm.manage_repos=1
#subscription-manager repos --enable=rhocp-4.18-for-rhel-9-x86_64-rpms --enable=fast-datapath-for-rhel-9-x86_64-rpms
######################

# Install packages
#sudo dnf install -y microshift-release-info podman composer-cli osbuild-composer

# Enable services
#sudo systemctl enable --now osbuild-composer.socket

# Composes won't use the system repos and they are in a different format from DNF, i.e redhat.repo
sudo composer-cli sources add microshift.toml
sudo composer-cli sources add fast-datapath.toml
# Copy blueprint template
cp -f "${BLUEPRINT_TEMPLATE}" "${BLUEPRINT_FILE}"

# Add in pull secret
sudo mkdir /etc/osbuild-worker
sudo cp "${SCRIPT_DIR}/pull-secret.json" /etc/osbuild-worker/pull-secret.json

# Get OpenShift Release Images to add
jq -r '.images | .[] | ("[[containers]]\nsource = \"" + . + "\"\n")' "${RELEASE_FILE}" >> "${BLUEPRINT_FILE}"

# Building the image

sudo composer-cli blueprints push microshift-blueprint-v0.0.1.toml

# Optional depsolve
#sudo composer-cli blueprints depsolve microshift-build

exit 0
BUILDID=$(sudo composer-cli compose start-ostree --ref "rhel/9/$(uname -m)/edge" "${EDGE_CONTAINER_NAME}" edge-container | awk '/^Compose/ {print $2}')



