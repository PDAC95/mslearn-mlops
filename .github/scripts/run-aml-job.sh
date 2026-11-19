#!/usr/bin/env bash
# Submit an Azure ML job, wait until it finishes and print its user log.
# Used instead of `az ml job create --stream`, whose log streaming fails on the
# current Azure ML CLI with "binascii.Error: Incorrect padding".
# Arguments are passed straight to `az ml job create`.
set -euo pipefail

JOB_NAME=$(az ml job create "$@" --query name -o tsv)
echo "Submitted Azure ML job: $JOB_NAME"

while true; do
  STATUS=$(az ml job show --name "$JOB_NAME" --query status -o tsv)
  echo "Job status: $STATUS"
  case "$STATUS" in
    Completed) break ;;
    Failed|Canceled|NotResponding)
      echo "Azure ML job ended with status $STATUS" >&2
      exit 1 ;;
  esac
  sleep 20
done

az ml job download --name "$JOB_NAME" --all --download-path ./job-output > /dev/null || echo "Warning: could not download job logs" >&2
find ./job-output -name std_log.txt -exec cat {} \;
