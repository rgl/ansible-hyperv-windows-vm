# About

[![Build status](https://github.com/rgl/ansible-hyperv-windows-vm/actions/workflows/build.yml/badge.svg)](https://github.com/rgl/ansible-hyperv-windows-vm/actions/workflows/build.yml)

This is an example Ansible project that creates a Windows Hyper-V Virtual Machine.

For a more complete Ansible Playbook see the [rgl/my-windows-ansible-playbooks repository](https://github.com/rgl/my-windows-ansible-playbooks).

# Usage

Install a Windows machine with Hyper-V, [`wasmtime`](https://github.com/bytecodealliance/wasmtime) and [`hadris-iso-cli-wasm`](https://github.com/rgl/hadris-iso-cli-wasm), like in [rgl/my-windows-ansible-playbooks](https://github.com/rgl/my-windows-ansible-playbooks), to serve as the  Hyper-V environment.

Configure an External Virtual Switch named `Bridge` in your Hyper-V environment.

Install the [test/templates/windows-2022-amd64 virtual machine template](https://github.com/rgl/windows-vagrant) in your Hyper-V environment.

Execute the following procedure in a Ubuntu machine.

Install Docker.

Open the [inventory file](inventory.yml) and modify the virtual machines details to fit your environment.

Set your Hyper-V details:

```bash
cat >secrets.sh <<'EOF'
export VM_HYPERV_HOSTNAME='192.168.8.22'
export VM_HYPERV_USERNAME='Administrator'
export VM_HYPERV_PASSWORD='vagrant'
export VM_HYPERV_TEMPLATE='C:/Users/Administrator/.vagrant.d/boxes/windows-2022-amd64/0.0.0/hyperv/Virtual Hard Disks/packer-windows-2022-amd64.vhdx'
export VM_HYPERV_STORAGE='C:/ProgramData/Microsoft/Windows/Hyper-V/Virtual Machines'
export VM_SWITCH='Bridge'
#export VM_VLAN_MODE='Access'
#export VM_VLAN_ID='1'
export VM_GATEWAY='192.168.8.1'
export VM_FIRST_IP='192.168.8.200'
EOF
source secrets.sh
```

Lint the playbooks:

```bash
./ansible-lint.sh --offline --parseable example.yml || echo 'ERROR linting'
./ansible-lint.sh --offline --parseable example-destroy.yml || echo 'ERROR linting'
```

List the inventory:

```bash
./ansible-inventory.sh --list --yaml
```

See the facts about the `hv` machine (the Hyper-V Host):

```bash
./ansible.sh hv -m ansible.builtin.setup
```

Run an ad-hoc command in the `hv` machine (the Hyper-V Host):

```bash
./ansible.sh hv -m win_command -a 'whoami /all'
./ansible.sh hv -m win_command -a 'cmd /c winrm enumerate winrm/config/listener'
./ansible.sh hv -m win_command -a 'cmd /c winrm get winrm/config'
./ansible.sh hv -m win_shell -a 'Get-PSSessionConfiguration'
```

Create and configure the `vm1` machine (the Hyper-V Guest) using the [`example.yml` playbook](example.yml):

```bash
./ansible-playbook.sh --limit=vm1 example.yml | tee ansible-example.log
```

Access the `vm1` machine:

```bash
vm1_vars="$(ANSIBLE_CALLBACK_RESULT_FORMAT=json ANSIBLE_CALLBACK_FORMAT_PRETTY=false \
    ./ansible.sh vm1 -m debug -a 'var=hostvars[inventory_hostname]' \
    | grep -oP '(?<=SUCCESS => )\{.*\}')"
vm1_user="$(jq -r '.["hostvars[inventory_hostname]"].ansible_user' <<<"$vm1_vars")"
vm1_host="$(jq -r '.["hostvars[inventory_hostname]"].ansible_host' <<<"$vm1_vars")"
ssh "$vm1_user@$vm1_host"
whoami /all
ipconfig /all
exit
```

Access the `vm1` machine using PowerShell Direct from within the `hv` machine:

```bash
hv_vars="$(ANSIBLE_CALLBACK_RESULT_FORMAT=json ANSIBLE_CALLBACK_FORMAT_PRETTY=false \
    ./ansible.sh hv -m debug -a 'var=hostvars[inventory_hostname]' \
    | grep -oP '(?<=SUCCESS => )\{.*\}')"
hv_user="$(jq -r '.["hostvars[inventory_hostname]"].ansible_user' <<<"$hv_vars")"
hv_host="$(jq -r '.["hostvars[inventory_hostname]"].ansible_host' <<<"$hv_vars")"
ssh "$hv_user@$hv_host"
powershell
Enter-PSSession `
    -VMName vm1 `
    -Credential (New-Object `
        System.Management.Automation.PSCredential(
            "vagrant",
            (ConvertTo-SecureString "vagrant" -AsPlainText -Force)))
$PSVersionTable # should show powershell 5.1
exit # exit PS Session
exit # exit hv powershell
exit # exit hv ssh
```

Destroy the `vm1` machine (the Hyper-V Guest) using the [`example-destroy.yml` playbook](example-destroy.yml):

```bash
./ansible-playbook.sh --limit=vm1 example-destroy.yml | tee ansible-example-destroy.log
```

# References

* [microsoft.hyperv Ansible Collection](https://galaxy.ansible.com/ui/repo/published/microsoft/hyperv)
* [microsoft.hyperv Ansible Collection repository](https://github.com/ansible-collections/microsoft.hyperv)
* [HVTools](https://github.com/michaelmsonne/HVTools)
