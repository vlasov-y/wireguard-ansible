Wireguard Ansible
===

## Features

Name | Status | Descritpion
--- | --- | ---
Multiple networks setup | beta | Configure multiple networks in single run
Separated execution | todo | Execute playbooks separately (not on all hosts at once)
Random preshared keys | beta | Generate random preshared keys
Random fwmark | beta | Generate random wireguard interface fwmark
Domain-based proxying | beta | Route traffic to domains from the list via Wireguard (only NetworkManager on Linux)
Masquarade | beta | Use host as gateway for other hosts
Custom scripts | beta | You can define additiona pre- post- commands to execute by systemd service
