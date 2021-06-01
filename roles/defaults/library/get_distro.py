#!/usr/bin/env python3

ANSIBLE_METADATA = {
    'metadata_version': '1.0',
    'status': ['release'],
}

DOCUMENTATION = '''
---
module: get_distro

short_description: Gets distribution and major release version

version_added: "2.8.5"

description:
    - "Used instead of full facts gathering"

options:

author:
    - Yurii Vlasov (@y.vlasov)
'''

EXAMPLES = '''
- name: Get distro info
  register: _distro
  get_distro:

- name: Install aptitude
  become: yes
  when: _distro.ubuntu
  apt:
    name: aptitude
    state: latest
'''

RETURN = '''
centos:
    description: True if it is CentOS
    type: bool
    returned: always
ubuntu:
    description: True if it is Ubuntu
    type: bool
    returned: always
version:
    description: Version major number
    type: str
    returned: always
'''

import subprocess
from ansible.module_utils.basic import AnsibleModule


def main():
    result = dict(
        changed=False,
        ubuntu=False,
        centos=False
    )

    module = AnsibleModule(
        argument_spec=dict(),
        supports_check_mode=True
    )

    # asserts
    try:
        distro = subprocess.check_output('. /etc/os-release && echo "$ID"', shell=True).decode().lower().strip()
        result['version'] = subprocess.check_output('. /etc/os-release && echo "$VERSION_ID"', shell=True).decode().lower().strip()
        result['ubuntu'] = distro == 'ubuntu'
        result['centos'] = distro == 'centos'
    except subprocess.CalledProcessError:
        module.fail_json(msg='Failed read /etc/os-release', **result)
    module.exit_json(**result)


if __name__ == '__main__':
    main()
