#!/usr/bin/env sh
set -e

LIST='{{ configuration_path }}/domains.list'
IPSETv4='{{ proxy_ipset }}-v4'
IPSETv6='{{ proxy_ipset }}-v6'
INTERVAL='300'

main() {
  if [ "$1" = 'start' ]; then
    echo "Waiting interval $INTERVAL"
    wc -l "$LIST" | xargs printf "%d domains total in %s\n"
    create_ipsets
    while true; do
      flush_ipsets >/dev/null
      resolve "$LIST" A "$IPSETv4"
      resolve "$LIST" AAAA "$IPSETv6"
      sleep "$INTERVAL"
    done
  elif [ "$1" = 'stop' ]; then
    destroy_ipsets
  else
    # in case if you launched this script manually with improper args
    echo "error: unknown action $1" >&2
    exit 1
  fi
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

destroy_ipsets() {
  if ipset list "$IPSETv4" 1>/dev/null 2>&1; then
    echo "Destroying $IPSETv4"
    ipset destroy "$IPSETv4"
  fi
  if ipset list "$IPSETv6" 1>/dev/null 2>&1; then
    echo "Destroying $IPSETv6"
    ipset destroy "$IPSETv6"
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
  TEMP="/tmp/dns-resolver@{{ network }}.txt"
  touch "$TEMP"
  # Add all IPv4 addresses directly
  grep -E '[0-9]{1,3}(\.[0-9]{1,3}){3}' "$FILE" | tee "$TEMP"
  # Filter out IPv4 because they have been already added
  grep -vE '[0-9]{1,3}(\.[0-9]{1,3}){3}' "$FILE" | \
  # Resolve domains from the list
  xargs dig +noall +answer -t "$TYPE"  | \
  # Save results to temp file
  tee -a "$TEMP" | \
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
  grep -vE '^(::1|::0|127\.0\.0\.[0-9]+|::|0\.0\.0\.0)$' | \
  xargs -I{} ipset add "$IPSET" {} -exist || \
  echo "IPset processing have failed!"
  # Remove temp file
  rm -f "$TEMP"
}

main "$@"
