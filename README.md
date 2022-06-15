# Foundry Template

Template for Smart Contract applications compatible with [foundry](https://github.com/foundry-rs/foundry).

## Usage

### Install dependencies

```bash
# Install tools from the nodejs ecosystem: prettier, solhint, husky and lint-staged
make nodejs-deps
# Install smart contract dependencies through `foundry update`
make update
```

### Create a local `.env` file and change the placeholder values

```bash
cp .env.example .env
```

### Build contracts

```bash
make build
```

### Test contracts

```bash
make test # using a local node listening on http://localhost:8545
# Or
ETH_RPC_URL='https://eth-goerli.alchemyapi.io/v2/<ALCHEMY_API_KEY>' make test # using a remote node
```

### Edit as needed

- Put contracts and tests in `src/`
- Modify the `Makefile` targets accordingly
