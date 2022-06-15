#!/bin/bash
set -eo pipefail

source "${BASH_SOURCE%/*}/_common.sh"

function verify() {
  normalize-env-vars
  check-required-etherscan-api-key

  local ADDRESS="$1"
  local CONTRACT="$2"
  local CONSTRUCTOR_ARGS="$3"

  local CONSTRUCTOR_ARGS_OPT=''
  if [ -n "$CONSTRUCTOR_ARGS" ]; then
    # Remove the 0x prefix from the constructor args
    CONSTRUCTOR_ARGS_OPT="--constructor-args ${CONSTRUCTOR_ARGS#0x}"
  fi

  local CHAIN="$(cast chain)"
  [ CHAIN = 'ethlive' ] && CHAIN='mainnet'

  verify-msg() {
    cat <<MSG
forge verify-contract \\
  --chain "$CHAIN" \\
  "$ADDRESS" "$CONTRACT" "$FOUNDRY_ETHERSCAN_API_KEY" $CONSTRUCTOR_ARGS_OPT
MSG
  }

  log "$(verify-msg)"

  forge verify-contract \
    --chain "$CHAIN" --watch \
    "$ADDRESS" "$CONTRACT" "$FOUNDRY_ETHERSCAN_API_KEY" $CONSTRUCTOR_ARGS_OPT
}

function check-required-etherscan-api-key() {
  [ -n "$FOUNDRY_ETHERSCAN_API_KEY" ] || die "$(err-msg-etherscan-api-key)"
}

function usage() {
  cat <<MSG
forge-verify.sh <address> <file>:<contract> [ --constructor-args <abi_encoded_args> ]

Examples:

    # Constructor does not take any arguments
    forge-verify.sh 0xdead...0000  src/MyContract.sol:MyContract

    # Constructor takes (uint, address) arguments. Don't forget to abi-encode them!
    forge-verify.sh 0xdead...0000 src/MyContract.sol:MyContract \\
        --constructor-args="\$(cast abi-encode 'constructor(uint, address)' 1 0x0000000000000000000000000000000000000000)"
MSG
}

# Executes the function if it's been called as a script.
# This will evaluate to false if this script is sourced by other script.
if [ "$0" = "$BASH_SOURCE" ]; then
  [ "$1" = "-h" -o "$1" = "--help" ] && {
    echo -e "\n$(usage)\n"
    exit 0
  }

  verify "$@"
fi
