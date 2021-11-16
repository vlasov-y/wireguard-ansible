#!/usr/bin/env python3

ANSIBLE_METADATA = {
    'metadata_version': '1.0',
    'status': ['release'],
}

DOCUMENTATION = '''
---
module: get_free_port

short_description: Gets free port

version_added: "2.8.5"

description:
    - "Used for looking for free port"

options:

author:
    - Yurii Vlasov (yuriy@vlasov.pro)
'''

EXAMPLES = '''
- name: Get free port
  register: _port
  get_free_port:

'''

RETURN = '''
port:
    description: Port number
    type: int
    returned: always
'''

from ansible.module_utils.basic import AnsibleModule

import socket
import random


def main():
    result = dict(
        changed=False,
        port=None
    )

    module = AnsibleModule(
        argument_spec=dict(),
        supports_check_mode=True
    )
    
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        tries = 0
        with open('/proc/sys/net/ipv4/ip_local_port_range', 'r') as f:
            start, end = f.read().split()

        while True:
            port = random.randint(int(start), int(end))
            try:
                s.bind(('', port))
            except OSError:
                tries += 1
                if tries == 100:
                    module.fail_json(msg='Failed to find a free port after {0} tries'.format(tries), **result)
                    break
                else:
                    continue                
            result['port'] = s.getsockname()[1]
            break
    finally:
        s.close()
    module.exit_json(**result)

if __name__ == '__main__':
    main()
