GREEN='\033[0;32m' # Green
NC='\033[0m'       # No Color
debug() {
  printf '%b\n' "${GREEN}${*}${NC}" >&2
}

log() {
  echo -e "$@" >&2
}

die() {
  log "$@"
  exit 1
}

# Normalizes the environment variables to be fully compatible with dapp.tools
# @see https://github.com/foundry-rs/foundry/issues/1869
normalize-env-vars() {
  local ENV_FILE="${BASH_SOURCE%/*}/../.env"
  [ -f "$ENV_FILE" ] && source "$ENV_FILE"

  export FOUNDRY_ETH_FROM="${FOUNDRY_ETH_FROM:-$ETH_FROM}"
  export FOUNDRY_ETH_KEYSTORE_DIR="${FOUNDRY_ETH_KEYSTORE_DIR:-$ETH_KEYSTORE}"
  export FOUNDRY_ETH_PASSWORD_FILE="${FOUNDRY_ETH_PASSWORD_FILE:-$ETH_PASSWORD}"

  if [ -z "$FOUNDRY_ETH_KEYSTORE_FILE" ]; then
    [ -z "$FOUNDRY_ETH_KEYSTORE_DIR" ] && die "$(err-msg-keystore-file)"
    # Foundry expects the Ethereum Keystore file, not the directory.
    # This step assumes the Keystore file for the deployed wallet includes $ETH_FROM in its name.
    export FOUNDRY_ETH_KEYSTORE_FILE="${FOUNDRY_ETH_KEYSTORE_DIR%/}/$(ls -1 $FOUNDRY_ETH_KEYSTORE_DIR |
      # -i: case insensitive
      # #0x: strip the 0x prefix from the the address
      grep -i ${FOUNDRY_ETH_FROM#0x})"
  fi

  [ -n "$FOUNDRY_ETH_KEYSTORE_FILE" ] || die "$(err-msg-keystore-file)"

  export FOUNDRY_ETHERSCAN_API_KEY="${FOUNDRY_ETHERSCAN_API_KEY:-$ETHERSCAN_API_KEY}"
  # Some commands require the prefixed env var, while others require the unprefixed one.
  export ETHERSCAN_API_KEY="$FOUNDRY_ETHERSCAN_API_KEY"
}

# Handle reading from the password file
extract-password() {
  [ -f "$FOUNDRY_ETH_PASSWORD_FILE" ] && cat "$FOUNDRY_ETH_PASSWORD_FILE"
}

err-msg-keystore-file() {
  cat <<MSG
ERROR: could not determine the location of the keystore file.

You should either define:

\t1. The FOUNDRY_ETH_KEYSTORE_FILE env var or;
\t2. Both FOUNDRY_ETH_KEYSTORE_DIR and FOUNDRY_ETH_FROM env vars.
MSG
}

err-msg-etherscan-api-key() {
  cat <<MSG
ERROR: cannot verify contracts without ETHERSCAN_API_KEY being set.

You should either:

\t1. Not use the --verify flag or;
\t2. Define the ETHERSCAN_API_KEY env var.
MSG
}

# Shameleslly copied from https://raw.githubusercontent.com/UrsaDK/getopts_long/master/lib/getopts_long.bash
getopts_long() {
  : "${1:?Missing required parameter -- long optspec}"
  : "${2:?Missing required parameter -- variable name}"

  local optspec_short="${1%% *}-:"
  local optspec_long="${1#* }"
  local optvar="${2}"

  shift 2

  if [[ "${#}" == 0 ]]; then
    local args=()
    while [[ ${#BASH_ARGV[@]} -gt ${#args[@]} ]]; do
      local index=$((${#BASH_ARGV[@]} - ${#args[@]} - 1))
      args[${#args[@]}]="${BASH_ARGV[${index}]}"
    done
    set -- "${args[@]}"
  fi

  builtin getopts "${optspec_short}" "${optvar}" "${@}" || return 1
  [[ "${!optvar}" == '-' ]] || return 0

  printf -v "${optvar}" "%s" "${OPTARG%%=*}"

  if [[ "${optspec_long}" =~ (^|[[:space:]])${!optvar}:([[:space:]]|$) ]]; then
    OPTARG="${OPTARG#${!optvar}}"
    OPTARG="${OPTARG#=}"

    # Missing argument
    if [[ -z "${OPTARG}" ]]; then
      OPTARG="${!OPTIND}" && OPTIND=$((OPTIND + 1))
      [[ -z "${OPTARG}" ]] || return 0

      if [[ "${optspec_short:0:1}" == ':' ]]; then
        OPTARG="${!optvar}" && printf -v "${optvar}" ':'
      else
        [[ "${OPTERR}" == 0 ]] ||
          echo "${0}: option requires an argument -- ${!optvar}" >&2
        unset OPTARG && printf -v "${optvar}" '?'
      fi
    fi
  elif [[ "${optspec_long}" =~ (^|[[:space:]])${!optvar}([[:space:]]|$) ]]; then
    unset OPTARG
  else
    # Invalid option
    if [[ "${optspec_short:0:1}" == ':' ]]; then
      OPTARG="${!optvar}"
    else
      [[ "${OPTERR}" == 0 ]] || echo "${0}: illegal option -- ${!optvar}" >&2
      unset OPTARG
    fi
    printf -v "${optvar}" '?'
  fi
}
