#!/usr/bin/env bash
# The fetched pool travels encrypted (#596; Freesound's API terms 1b and 4a: intermediate copies
# only, never published from anywhere but the game). The session makes a key pair, commits only
# the public half, and opens the pool it gets back with the private half, which never leaves the
# session's scratch space.
#
#   tools/sounds/pool_key.sh new  DIR        # DIR/pool_key.pem (private, keep out of git);
#                                            # tools/sounds/pool_key.pub (commit it, then push)
#   tools/sounds/pool_key.sh seal SRC OUT    # on the runner: SRC -> OUT/pool.tgz.enc + OUT/key.enc
#   tools/sounds/pool_key.sh open DIR POOL OUT   # POOL: a checkout of the pool branch -> OUT
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
case "${1:-}" in
  new)
    mkdir -p "$2"
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out "$2/pool_key.pem" 2>/dev/null
    openssl pkey -in "$2/pool_key.pem" -pubout -out "$HERE/pool_key.pub"
    echo "private: $2/pool_key.pem  public: $HERE/pool_key.pub" ;;
  seal)
    mkdir -p "$3"
    k="$(mktemp)"; openssl rand -hex 32 > "$k"
    tar -C "$2" -czf - . | openssl enc -aes-256-cbc -pbkdf2 -salt -pass "file:$k" -out "$3/pool.tgz.enc"
    openssl pkeyutl -encrypt -pubin -inkey "$HERE/pool_key.pub" -pkeyopt rsa_padding_mode:oaep -in "$k" -out "$3/key.enc"
    rm -f "$k" ;;
  open)
    mkdir -p "$4"
    k="$(mktemp)"
    openssl pkeyutl -decrypt -inkey "$2/pool_key.pem" -pkeyopt rsa_padding_mode:oaep -in "$3/key.enc" -out "$k"
    openssl enc -d -aes-256-cbc -pbkdf2 -pass "file:$k" -in "$3/pool.tgz.enc" | tar -C "$4" -xzf -
    rm -f "$k" ;;
  *) sed -n 2,12p "$0"; exit 2 ;;
esac
