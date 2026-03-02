# Security

## Never commit
- Mnemonics / seed phrases
- Private keys (*.key, *.pem)
- Keyrings / wallet directories
- `.env` files
- Node `data/` directories or databases
- SSH keys

## Pre-PR checklist
- `git status`
- `git diff`
- `grep -R "mnemonic\|seed\|private\|keyring" -n .`
