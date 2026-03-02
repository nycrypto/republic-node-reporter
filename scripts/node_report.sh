#!/usr/bin/env bash
set -euo pipefail

# Generic Cosmos/Tendermint/CometBFT node reporter
# READ-ONLY: does not sign tx, does not require keys.

RPC_URL="${NODE_RPC_URL:-http://127.0.0.1:26657}"
SERVICE="${NODE_SERVICE:-}"
SINCE="${NODE_LOG_SINCE:-24 hours ago}"
MAX_LOG_LINES="${NODE_LOG_MAX_LINES:-2000}"
BIN="${NODE_BIN:-}"
VALOPER="${NODE_VALOPER:-}"

curl_json() { curl -fsS --max-time 6 "$1"; }

status_json=""
net_json=""
rpc_err=""

if ! status_json="$(curl_json "$RPC_URL/status")"; then
rpc_err="RPC status fetch failed: $RPC_URL/status"
else
net_json="$(curl -fsS --max-time 6 "$RPC_URL/net_info" 2>/dev/null || true)"
fi

height="$(jq -r '.result.sync_info.latest_block_height // "N/A"' <<<"$status_json" 2>/dev/null || echo N/A)"
catching_up="$(jq -r 'if (.result.sync_info|has("catching_up")) then (.result.sync_info.catching_up|tostring) else "N/A" end' <<<"$status_json" 2>/dev/null || echo N/A)"
moniker="$(jq -r '.result.node_info.moniker // "N/A"' <<<"$status_json" 2>/dev/null || echo N/A)"
network="$(jq -r '.result.node_info.network // "N/A"' <<<"$status_json" 2>/dev/null || echo N/A)"
voting_power="$(jq -r '.result.validator_info.voting_power // "N/A"' <<<"$status_json" 2>/dev/null || echo N/A)"
cons_addr_hex="$(jq -r '.result.validator_info.address // "N/A"' <<<"$status_json" 2>/dev/null || echo N/A)"
peers="$(jq -r '.result.n_peers // "N/A"' <<<"$net_json" 2>/dev/null || echo N/A)"

active_set="N/A"
if [[ "$voting_power" =~ ^[0-9]+$ ]]; then
(( voting_power > 0 )) && active_set="YES" || active_set="NO"
fi

# Optional validator details if BIN+VALOPER provided
val_status="N/A"
val_jailed="N/A"
val_tokens="N/A"
val_commission="N/A"

if [[ -n "$BIN" && -n "$VALOPER" ]]; then
val_json="$("$BIN" query staking validator "$VALOPER" --node "$RPC_URL" -o json 2>/dev/null || true)"
if [[ -n "$val_json" ]]; then
val_status="$(jq -r '.validator.status // "N/A"' <<<"$val_json" 2>/dev/null || echo N/A)"
val_jailed="$(jq -r 'if (.validator|has("jailed")) then (.validator.jailed|tostring) else "N/A" end' <<<"$val_json" 2>/dev/null || echo N/A)"
val_tokens="$(jq -r '.validator.tokens // "N/A"' <<<"$val_json" 2>/dev/null || echo N/A)"
val_commission="$(jq -r '.validator.commission.commission_rates.rate // "N/A"' <<<"$val_json" 2>/dev/null || echo N/A)"
fi
fi

# Logs (best-effort)
logs=""
log_src="N/A"
if [[ -n "$SERVICE" ]]; then
logs="$(journalctl -u "$SERVICE" --since "$SINCE" -n "$MAX_LOG_LINES" --no-pager 2>/dev/null || true)"
[[ -n "$logs" ]] && log_src="journalctl:$SERVICE"
fi

crit_count="N/A"
crit_tail=""
if [[ -n "$logs" ]]; then
crit_lines="$(grep -Eai 'panic|fatal|\\bCRIT\\b|segfault|consensus failure|double sign|disk I/O error|corrupt|unable to start|exception' <<<"$logs" || true)"
if [[ -z "$crit_lines" ]]; then
crit_count=0
else
crit_count="$(wc -l <<<"$crit_lines" | tr -d ' ')"
crit_tail="$(tail -n 5 <<<"$crit_lines" || true)"
fi
fi

now_local="$(date +"%Y-%m-%d %H:%M:%S %Z")"

cat <<EOF
Node daily status — $now_local

RPC: $RPC_URL
Network: $network
Moniker: $moniker
Block height: $height
Catching up: $catching_up
Peers: $peers

Validator active set (voting_power>0): $active_set (voting_power=$voting_power)
Consensus addr (hex): $cons_addr_hex
Valoper: ${VALOPER:-N/A}
Validator status: $val_status
Validator jailed: $val_jailed
Validator tokens: $val_tokens
Validator commission rate: $val_commission

Logs (since: $SINCE) source: $log_src
Critical hits: $crit_count
EOF

if [[ -n "$crit_tail" ]]; then
echo
echo "Last critical lines:"
echo "$crit_tail"
fi

if [[ -n "$rpc_err" ]]; then
echo
echo "WARN: $rpc_err"
fi
