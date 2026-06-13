#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <folder-name>"
  echo ""
  echo "  folder-name   Subfolder inside secrets/ containing a .env file."
  echo "                The secret will be named after the folder."
  echo ""
  echo "Examples:"
  echo "  $0 article-news-raw"
  exit 1
}

FOLDER="${1:-}"
NAMESPACE="default"

if [[ -z "$FOLDER" ]]; then
  echo "Error: folder name is required." >&2
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRET_DIR="$SCRIPT_DIR/$FOLDER"
ENV_FILE="$SECRET_DIR/.env"
SECRET_NAME="$FOLDER"

if [[ ! -d "$SECRET_DIR" ]]; then
  echo "Error: folder '$SECRET_DIR' does not exist." >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: no .env file found in '$SECRET_DIR'." >&2
  exit 1
fi

kubectl create secret generic "$SECRET_NAME" \
  --namespace "$NAMESPACE" \
  --from-env-file="$ENV_FILE" \
  --dry-run=client -o yaml \
  | kubectl apply -f -

echo "Secret '$SECRET_NAME' applied in namespace '$NAMESPACE'."
