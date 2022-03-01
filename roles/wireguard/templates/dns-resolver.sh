#!/usr/bin/env sh
set -e

LIST='{{ configuration_path }}/domains.list'
IPSETv4='{{ ipset }}-v4'
IPSETv6='{{ ipset }}-v6'
INTERVAL='300'

main() {
  echo "Waiting interval $INTERVAL"
  wc -l "$LIST" | xargs printf "%d domains total in %s\n"
  create_ipsets
  while true; do
    flush_ipsets >/dev/null
    resolve "$LIST" A "$IPSETv4" >/dev/null
    resolve "$LIST" AAAA "$IPSETv6" >/dev/null
    sleep "$INTERVAL"
  done
}

create_ipsets() {
  if ! ipset list "$IPSETv4" 1>/dev/null 2>&1; then
    echo "Creating $IPSETv4"
    ipset create "$IPSETv4" hash:ip family inet
  fi
  if ! ipset list "$IPSETv6" 1>/dev/null 2>&1; then
    echo "Creating $IPSETv6"
    ipset create "$IPSETv6" hash:ip family inet6
  fi
}

flush_ipsets() {
  echo "Flushing $IPSETv4"
  ipset flush "$IPSETv4"
  echo "Flushing $IPSETv6"
  ipset flush "$IPSETv6"
}

resolve() {
  FILE="$1"
  TYPE="$2"
  IPSET="$3"
  TEMP="$(mktemp)"
  # Resolve domains from the list
  < "$FILE" xargs dig +noall +answer -t "$TYPE"  | \
  # Save results to temp file
  tee "$TEMP" | \
  # Select only CNAMEs from first resolution
  awk '$4~/^CNAME$/{print $NF}' | sort | uniq | \
  # Resolve CNAMEs
  xargs dig +noall +answer -t "$TYPE" | \
  # Append to the same file
  tee -a "$TEMP" | \
  # Count number of lines and print info
  wc -l | \
  xargs printf "%d $TYPE domains resolved from $FILE\n"
  # Add all addresses to the ipset
  awk "\$4~/^$TYPE\$/{print \$NF}" "$TEMP" | \
  # Filter out resereved
  grep -vE '^(::1|::0|127.0.0.[0-9]+)$' |\
  xargs -I{} ipset add "$IPSET" {} -exist
  # Remove temp file
  rm -f "$TEMP"
}

main "$@"
