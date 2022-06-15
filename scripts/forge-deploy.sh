#!/bin/bash
set -eo pipefail

source "${BASH_SOURCE%/*}/_common.sh"

deploy() {
  normalize-env-vars

  local PASSWORD="$(extract-password)"
  if [ -n "$PASSWORD" ]; then
    PASSWORD_OPT="--password=${PASSWORD}"
  fi

  check-required-etherscan-api-key

  # Log the command being issued, making sure not to expose the password
  log "forge create --keystore="$FOUNDRY_ETH_KEYSTORE_FILE" $(sed 's/=.*$/=[REDACTED]/' <<<"${PASSWORD_OPT}") $@"
  forge create --keystore="$FOUNDRY_ETH_KEYSTORE_FILE" ${PASSWORD_OPT} $@
}

check-required-etherscan-api-key() {
  # Require the Etherscan API Key if --verify option is enabled
  set +e
  if grep -- '--verify' <<<"$@" >/dev/null; then
    [ -n "$FOUNDRY_ETHERSCAN_API_KEY" ] || die "$(err-msg-etherscan-api-key)"
  fi
  set -e
}

usage() {
  cat <<MSG
forge-deploy.sh --contract <file>:<contract> [ --verify ] [ --constructor-args ...args ]

Examples:

    # Constructor does not take any arguments
    forge-deploy.sh src/MyContract.sol:MyContract --verify

    # Constructor takes (uint, address) arguments
    forge-deploy.sh src/MyContract.sol:MyContract --verify --constructor-args 1 0x0000000000000000000000000000000000000000
MSG
}

if [ "$0" = "$BASH_SOURCE" ]; then
  optspec="h help contract: verify constructor-args"

  contract=
  has_constructor_args=0
  should_verify=0

  while getopts_long "$optspec" OPT; do
    case "$OPT" in
      'h' | 'help')
        echo -e "$(usage)"
        exit 0
        ;;
      'contract')
        [ -z "$OPTARG" ] && {
          log "\n--contract option is missing its argument\n"
          die "$(usage)"
        }
        contract="$OPTARG"
        ;;
      'verify')
        should_verify=1
        ;;
      'constructor-args')
        has_constructor_args=1
        # Constructor args must be the last arguments
        break
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

  debug $@

  [ -n "$contract" ] || die "Option --contract is required\n\n$(usage)"

  args=()
  [ $should_verify -eq 1 ] && args+=('--verify')

  if [ $has_constructor_args -eq 0 ]; then
    deploy "$contract" "${args[@]}"
  else
    deploy "$contract" "${args[@]}" --constructor-args "$@"
  fi
fi
