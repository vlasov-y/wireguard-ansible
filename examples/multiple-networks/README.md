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
  localhost["Laptop (10.0.0.2/24)"] --> vpn["Endpoint server (10.0.0.1/24)"]
  server["Home server (10.0.0.3/24)"] --> vpn
```

Using this network we will be able to connect to our home server from the laptop no matter where are we trying to connect from. In other words: 10.0.0.2 can reach 10.0.0.3 via 10.0.0.1.

## VPN network

```mermaid
graph BT
  localhost["Laptop (10.0.1.2/24)"] --> vpn["Endpoint server (10.0.1.1/24)"]
  phone["Smartphone (10.0.1.10/24)"] --> vpn
```

Some sites are blocked in our country, but we still want to access them, so we use our endpoint server as a gateway (do not forget to set proper AllowedIPs list and enable masquerade on the VPN server). And also, we have a smartphone that, of course, cannot be added to the inventory directly, so we *specify its public and preshared keys in the vars directly* and also *set static keys for endpoint server to use* (because we do not want to configure VPN on the tablet after each ansible run because endpoint's keys can be regenerated)
