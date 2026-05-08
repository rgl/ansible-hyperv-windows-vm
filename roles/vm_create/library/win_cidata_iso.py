#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_cidata_iso
short_description: Create a cloud-init data (aka cidata) ISO.
description:
  - Create a cloud-init data (aka cidata) ISO.
  - In the Hyper-V host, you must pre install wasmtime.exe and hadris-iso-cli.wasm.
options:
  path:
    description:
      - ISO destination path.
    type: path
  meta_data:
    description:
      - Contents of the meta-data file.
    type: str
    required: false
  network_config:
    description:
      - Contents of the network-config file.
    type: str
    required: false
  user_data:
    description:
      - Contents of the user-data file.
    type: str
    required: false
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Create cidata ISO
  win_cidata_iso:
    path: c:/example-cidata.iso
    meta_data: |
      # TODO
    network_config: |
      # TODO
    user_data: |
      # TODO
'''

RETURN = '''
path:
  description:
    - Full path for the created ISO.
  returned: always
  type: path
'''
