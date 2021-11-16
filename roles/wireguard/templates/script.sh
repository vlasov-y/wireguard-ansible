#jinja2: trim_blocks:False
#!/usr/bin/env sh
set -ex

IF='{{ interface }}'
ADDR='{{ wireguard_addresses[network].split("/")[0] }}'
CIDR='{{ wireguard_addresses[network].split("/")[1] }}'
FULL_ADDR="${ADDR}/${CIDR}"
NETWORK='{{ wireguard_networks[network] }}'
CONFIG='{{ configuration_path }}/wireguard.conf'
FWMARK='{{ fwmark }}'
RT_NAME='{{ rt_table.name }}'
RT_ID='{{ rt_table.id }}'
# interface that is used in default route
GW_IF="$(awk '$2 == 00000000 { print $1 }' /proc/net/route)"
{%- if network in wireguard_proxy_domains %}
PROXY_IPSET_v4='{{ ipset }}-v4'
PROXY_IPSET_v6='{{ ipset }}-v6'
PROXY_FWMARK='{{ proxy_fwmark }}'
{%- endif %}

# entrypoint
main() {
  if [ "$1" = 'start' ]; then
    # executed on systemctl start
    {{ 'prestart' if wireguard_extra_config|json_query(network + '.prestart') }}
    start_interface
    {{ 'enable_proxy' if network in wireguard_proxy_domains }}
    {{ 'enable_masquarade' if network in wireguard_masquarade }}
    {{ 'poststart' if wireguard_extra_config|json_query(network + '.poststart') }}
  elif [ "$1" = 'stop' ]; then
    # executed on systemctl stop
    {{ 'prestop' if wireguard_extra_config|json_query(network + '.prestop') }}
    stop_interface
    {{ 'disable_proxy' if network in wireguard_proxy_domains }}
    {{ 'disable_masquarade' if network in wireguard_masquarade }}
    {{ 'poststop' if wireguard_extra_config|json_query(network + '.poststop') }}
  else
    # in case if you launched this script manually with improper args
    echo "error: unknown action $1" >&2
    exit 1
  fi
}

# adds or removal of ip rules
# note: does not work with 'suppress_prefixlength 0 table main prio 0'
#   because list command fails
_iprule() {
  ACTION="$1"
  shift 1
  RULE_EXISTS="$(ip rule list "$@" | grep -qE ".+" && echo "true" || echo "false")"
  if [ "$ACTION" = 'add' ] && ! $RULE_EXISTS; then
    ip rule add "$@"
  elif [ "$ACTION" = 'del' ] && $RULE_EXISTS; then
    ip rule del "$@"
  fi
}

# adds or removes ip route
_iproute() {
  ACTION="$1"
  shift 1
  ROUTE_EXISTS="$(ip route show "$@" | grep -qE ".+" && echo "true" || echo "false")"
  if [ "$ACTION" = 'add' ] && ! $ROUTE_EXISTS; then
    ip route add "$@"
  elif [ "$ACTION" = 'del' ] && $ROUTE_EXISTS; then
    ip route del "$@"
  fi
}

# creates or destroys iphash ipset
_ipset() {
  ACTION="$1"
  IPSET="$2"
  FAMILY="$3"
  IPSET_EXISTS="$(ipset list "$IPSET" | grep -qE '.+' && echo "true" || echo "false")"
  if [ "$ACTION" = 'add' ] && ! $IPSET_EXISTS; then
    ipset create "$IPSET" iphash family "$FAMILY"
  elif [ "$ACTION" = 'del' ] && $IPSET_EXISTS; then
    ipset destroy "$IPSET"
  fi
}

# launchs wireguard interface itself
start_interface() {
  # create device
  if ! ip link show type wireguard | awk -F: '/:/{print $2}' | grep -qF "${IF}"; then
    ip link add dev "$IF" type wireguard
  fi
  # assign IP address to that device
  if ! ip addr show dev "$IF" | grep -qF "$FULL_ADDR"; then
    ip addr add dev "$IF" "$FULL_ADDR"
  fi
  # load wireguard.conf for this device
  wg setconf "$IF" "$CONFIG"
  # ifup wg interface
  ip link set up "$IF"
  # add route to wireguard network from main table
  _iproute add "$NETWORK" dev "$IF" src "$ADDR" table main
  # add default route to wireguard's route table
  _iproute add default dev "$IF" src "$ADDR" table "$RT_NAME"
  # packets from wireguard interface should be routed from main table
  _iprule add fwmark "$FWMARK" table main
  # enable masquarade for outgoing connection
  iptables -t nat -I POSTROUTING -o "$IF" -j MASQUERADE
}

# stops wireguard and removes interface
stop_interface() {
  # disable masquarade for outgoing connection
  iptables -t nat -D POSTROUTING -o "$IF" -j MASQUERADE || true
  # remove route from main table
  _iproute del "$NETWORK" dev "$IF" src "$ADDR" table main
  # remove route from wireguard's table
  _iproute del default dev "$IF" src "$ADDR" table "$RT_NAME"
  # remove rule for wiregaurd fwmark from main
  _iprule del fwmark "$FWMARK" table main
  # delete device
  ip link del dev "$IF"
}
{{''}}
{%- if network in wireguard_masquarade %}
# enables DNAT from wireguard
enable_masquarade() {
  iptables -t nat -I POSTROUTING -s "$NETWORK" ! -d "$NETWORK" -j MASQUERADE
  iptables -I FORWARD -i "$IF" -s "$NETWORK" -j ACCEPT 
}

# disables DNAT
disable_masquarade() {
  iptables -t nat -D POSTROUTING -s "$NETWORK" ! -d "$NETWORK" -j MASQUERADE
  iptables -D FORWARD -i "$IF" -s "$NETWORK" -j ACCEPT
}
{%- endif %}
{{''}}
{%- if network in wireguard_proxy_domains %}
# enables domain-based proxying over wireguard
enable_proxy() {
  # create ipset for dnsmasq
  _ipset add "$PROXY_IPSET_v4" inet
  _ipset add "$PROXY_IPSET_v6" inet6
  # mark IPs from ipset with mark $PROXY_FWMARK
  iptables -t mangle -I OUTPUT -m set --match-set "$PROXY_IPSET_v4" dst -j MARK --set-mark "$PROXY_FWMARK"
  ip6tables -t mangle -I OUTPUT -m set --match-set "$PROXY_IPSET_v6" dst -j MARK --set-mark "$PROXY_FWMARK"
  # forward packets with mark $PROXY_FWMARK over wireguard's table
  _iprule add fwmark "$PROXY_FWMARK" table "$RT_NAME"
}

# disables domain-based proxying over wireguard
disable_proxy() {
  # disable marking
  iptables -t mangle -D OUTPUT -m set --match-set "$PROXY_IPSET_v4" dst -j MARK --set-mark "$PROXY_FWMARK"
  ip6tables -t mangle -D OUTPUT -m set --match-set "$PROXY_IPSET_v6" dst -j MARK --set-mark "$PROXY_FWMARK"
  # remove rule for routing over wireguard network
  _iprule del fwmark "$PROXY_FWMARK" table "$RT_NAME"
  # remove ipset itself
  _ipset del "$PROXY_IPSET"
}
{%- endif %}
{{''}}
{%- for key in (wireguard_extra_config[network]|default({})).keys()|list %}
{{ key }}() {
  {{ wireguard_extra_script[network][key] | join('\n') | indent(width=2, first=False) }}
}
{%- endfor %}

main "$@"
