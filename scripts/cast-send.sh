#!/bin/bash
set -eo pipefail

source "${BASH_SOURCE%/*}/_common.sh"

send() {
  normalize-env-vars

  local PASSWORD="$(extract-password)"
  if [ -n "$PASSWORD" ]; then
    PASSWORD_OPT="--password=${PASSWORD}"
  fi

  local RESPONSE
  # Log the command being issued, making sure not to expose the password
  log "cast send --keystore="$FOUNDRY_ETH_KEYSTORE_FILE" $(sed 's/=.*$/=[REDACTED]/' <<<"$PASSWORD_OPT") --json" $(printf ' %q' "$@")
  RESPONSE=$(cast send --keystore="$FOUNDRY_ETH_KEYSTORE_FILE" "$PASSWORD_OPT" --json "$@" | tee >(cat 1>&2))

  jq -r '.transactionHash' <<<"$RESPONSE"
}

usage() {
  cat <<MSG
cast-send.sh <address> <method_signature> [ ...args ]

Examples:

    # Method does not take any arguments
    cast-send.sh 0xdead...0000 "someFunc()"

    # Method takes (uint, address) arguments
    cast-send.sh 0xdead...0000 'anotherFunc(uint, address)' --args 1 0x0000000000000000000000000000000000000000
MSG
}

if [ "$0" = "$BASH_SOURCE" ]; then
  [ "$1" = "-h" -o "$1" = "--help" ] && {
    echo -e "\n$(usage)\n"
    exit 0
  }

  send "$@"
fi
