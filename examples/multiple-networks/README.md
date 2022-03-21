Multiple networks
===

## Overview

This is general interaction overview.

```mermaid
graph BT
  localhost["Laptop"] --> vpn["Endpoint server"]
  server["Home server"] --> vpn
```

We have two networks: *home* and *vpn*

## Home network

```mermaid
graph BT
  localhost["Laptop (192.168.99.2/24)"] --> vpn["Endpoint server (192.168.99.1/24)"]
  server["Home server (192.168.99.3/24)"] --> vpn
```

Using this network we will be able to connect to our home server from the laptop no matter where are we trying to connect from. In other words: 192.168.99.2 can reach 192.168.99.3 via 192.168.99.1.

## VPN network

```mermaid
graph BT
  localhost["Laptop (10.0.0.2/24)"] --> vpn["Endpoint server (10.0.0.1/24)"]
  phone["Smartphone (10.0.0.10/24)"] --> vpn
```

Some sites are blocked in our country, but we still want to access them, so we use our endpoint server as a gateway (do not forget to set proper AllowedIPs list and enable masquerade on the VPN server). And we specify preshared and public keys for our smartphone to list it on VPN server.
