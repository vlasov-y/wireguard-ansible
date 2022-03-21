Wireguard Ansible
===

## TL;DR

Check examples folder, template your files basing on `group_vars` and `host_vars` example.  
In order to generate wireguard keys for the configuration execute code below in the shell.

```shell
wg genkey | \
tee private | \
wg pubkey > public && \
printf "private: %s\npublic: %s\n" "$(cat private)" "$(cat public)" && \
rm private public
```

To generate presharedKey run: `wg genpsk`.  
All keys are specified in the one place. Preshared key is used for all hosts in scope of Wireguard network, you cannot specify different keys for links in scope of one network.
  
You can run playbook on one host separately like this:

```shell
ansible-playbook all.yml -i inventory.yml -l laptop
```

## Features

| Name                    | Status      | Description                                                                         |
| ----------------------- | ----------- | ----------------------------------------------------------------------------------- |
| Multiple networks setup | implemented | Configure multiple networks in single run                                           |
| Separated execution     | implemented | Execute playbooks separately (not on all hosts at once)                             |
| Domain-based proxying   | implemented | Route traffic to domains from the list via Wireguard (only NetworkManager on Linux) |
| Masquarade              | implemented | Use host as gateway for other hosts                                                 |
| Custom scripts          | implemented | You can define additiona pre- post- commands to execute by systemd service          |

## Deprecated and removed

| Name                  | Status  | Description                                |
| --------------------- | ------- | ------------------------------------------ |
| Random preshared keys | removed | Generate random preshared keys             |
| Random keys           | removed | Generate random keys if are not set        |
| Random fwmark         | removed | Generate random wireguard interface fwmark |
