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
forge-verify.sh --address <address> --contract <file>:<contract> [ --constructor-args <abi_encoded_args> ]

Examples:

    # Constructor does not take any arguments
    forge-verify.sh --address 0xdead...0000  --contract src/MyContract.sol:MyContract

    # Constructor takes (uint, address) arguments. Don't forget to abi-encode them!
    forge-verify.sh 0xdead...0000 src/MyContract.sol:MyContract \\
        --constructor-args="\$(cast abi-encode 'constructor(uint, address)' 1 0x0000000000000000000000000000000000000000)"
MSG
}

# Executes the function if it's been called as a script.
# This will evaluate to false if this script is sourced by other script.
if [ "$0" = "$BASH_SOURCE" ]; then
  optspec="h help address: contract: constructor-args:"

  address=
  contract=
  constructor_args=

  while getopts_long "$optspec" OPT; do
    case "$OPT" in
      'h' | 'help')
        echo -e "$(usage)"
        exit 0
        ;;
      'address')
        [ -z "$OPTARG" ] && {
          log "\n--address option is missing its argument\n"
          die "$(usage)"
        }
        address="$OPTARG"
        ;;
      'contract')
        [ -z "$OPTARG" ] && {
          log "\n--contract option is missing its argument\n"
          die "$(usage)"
        }
        contract="$OPTARG"
        ;;
      'constructor-args')
        [ -z "$OPTARG" ] && {
          log "\n--constructor-args option is missing its argument\n"
          die "$(usage)"
        }
        constructor_args="$OPTARG"
        ;;
      ':')
        # bad long option
        log "\nMissing argument for option --${OPTARG}\n"
        die "$(usage)"
        ;;
      ?)
        log "\nIllegal option -- ${BOLD}${OPT}${OFF}\n"
        die "$(usage)"
        ;;
    esac
  done
  shift $((OPTIND - 1))
  [[ "${1}" == "--" ]] && shift

  [ -n "$address" ] || die "Option --address is required\n\n$(usage)"
  [ -n "$contract" ] || die "Option --contract is required\n\n$(usage)"

  verify "$address" "$contract" "$constructor_args"
fi
