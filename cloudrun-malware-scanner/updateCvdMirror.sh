#!/bin/bash
#
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Utility to populate and update a local copy of the ClamAV virus definitions
# in a Cloud Storage bucket.
#
# This uses the ClamAV private mirror update tool.
# https://github.com/Cisco-Talos/cvdupdate

CMD=$(basename "$0")

export PATH="$PATH:$HOME/.local/bin" # add pipx locations to path.
if ! which cvdupdate >/dev/null  ; then
    echo "cvdupdate is not installed" >&2
    exit 1
fi

CVD_MIRROR_BUCKET="$1"
if [[ -z "${CVD_MIRROR_BUCKET}" ]] ; then
    echo "Usage: ${CMD} CVD_MIRROR_BUCKET_NAME" >&2
    exit 1
fi

# Use a GCS file as a mutex to prevent multiple updates from happening at once
# which may be possible if multiple cloud run instances are started.
LOCKFILE_NAME=cdvupdates.lock
LOCKFILE_PATH="gs://${CVD_MIRROR_BUCKET}/${LOCKFILE_NAME}"
LOCKFILE_EXPIRY_MINS=10

# Use gcloud storage cp to create a lockfile containing the current timestamp
# --if-generation-match=0 will cause the cp to fail if the file already exists
# and the loop will then be executed. This makes the command an atomic
# "create-if-not-exists" operation.
echo "${CMD} Attempting to create ${LOCKFILE_PATH}"
while ! {
            date +%s > /tmp/${LOCKFILE_NAME} && \
            gcloud storage cp --quiet \
                /tmp/${LOCKFILE_NAME} \
                "${LOCKFILE_PATH}" \
                --if-generation-match=0 2>/dev/null >/dev/null
        }
do
    # Lockfile exists - check that it has not expired.
    LOCK_EXPIRED_TIMESTAMP="$(date +%s --date="now - ${LOCKFILE_EXPIRY_MINS} minutes")"
    LOCKFILE_TIMESTAMP=$(gsutil -q cat "${LOCKFILE_PATH}" 2>/dev/null )
    if [[ "${LOCKFILE_TIMESTAMP}" && "${LOCKFILE_TIMESTAMP}" -lt "${LOCK_EXPIRED_TIMESTAMP}" ]] ; then
        echo "${CMD} ${LOCKFILE_PATH} has expired, removing"
        gsutil -q rm "${LOCKFILE_PATH}"
        LOCKFILE_TIMESTAMP=""
    else
        # Lockfile created recently, wait for it to be removed or expire
        echo "${CMD} Waiting for ${LOCKFILE_PATH}"
        sleep 30
    fi
done
echo "${CMD} successfully created ${LOCKFILE_PATH}"

# Ensure lockfile is removed on exit.
trap "echo ${CMD} removing ${LOCKFILE_PATH} ; gsutil -q rm ${LOCKFILE_PATH}" EXIT

# Copy the existing CVDs from GCS to a local directory.
# ignore errors as it implies empty db in mirror (ie first run).
mkdir -p ./cvds
echo "${CMD} Downloading CVD mirror from gs://${CVD_MIRROR_BUCKET}/cvds/"
gsutil -m -q rsync -d -c -r -x cvds/log "gs://${CVD_MIRROR_BUCKET}/cvds/" ./cvds

set -o errexit

if [[ ! -e ./cvds/config.json ]] ; then
    # Create an initial cvdupdater config to use local directory.
    cvdupdate config set -c ./cvds/config.json -d ./cvds -l ./cvds/log
fi

# Update databases in local directory
echo "${CMD} Checking for CVD Updates"
cvdupdate update -V -c ./cvds/config.json

# show logs on success (failures will have been reported to stderr)
cat ./cvds/log/*.log

# Push any updated databases back to GCS
echo "${CMD} Updating CVD mirror at gs://${CVD_MIRROR_BUCKET}/cvds/"
gsutil -m -q rsync -d -c -r -x '.*\.log' ./cvds "gs://${CVD_MIRROR_BUCKET}/cvds/"

echo "${CMD} completed"
