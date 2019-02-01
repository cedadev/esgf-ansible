# ESGF-Ansible

## Introduction

The deployment of ESGF Nodes has traditionally been done by a mix of scripts and manual admin actions. This repository holds files which are used by the popular automated system configuration tool [Ansible](https://www.ansible.com/) that will perform the ESGF Node deployment.

## Basic Info

Ansible runs from a 'control' machine and deploys the configuration to 'managed' machines.

The simple requirements for the control machine is to have Ansible installed in some way. This can be done via a system package manager, or simply via pip, the Python package manager into a Python environment. The later is the recommended way as this repository was developed and tested with the latest Ansible at the time, `2.7`. It has been found that Ansible `2.4` is not supported. __Using anything other than `ansible==2.7` will result in untested behavior.__

The simple requirement for the managed machine is that it can be accessed via SSH from the control machine and that the managed machine has a Python interpreter. Ansible works reliably with Python 2 on the managed machine. Ansible is working towards supporting Python 3 on managed machines, see [their info](https://docs.ansible.com/ansible/latest/reference_appendices/python_3_support.html), but is aware of incompatabilities. Since the system Python on CentOS/Redhat 6 and 7 is 2.6 and 2.7, respectively, this is not an issue.  Also, there must be some way to have escalated privileges on the managed machine to deploy the configuration. This is described more below.

For all the details and features of Ansible see:
- [Ansible Docs](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Modules](https://docs.ansible.com/ansible/latest/modules/modules_by_category.html)

## Usage

### Info
To deploy the specified configurations to your managed machines it is required to specify hosts in an 'inventory' file. It is often convenient to specify two of these inventory files, a 'production' and a 'staging' (or 'testing') file, if the resources for both are available. These must be populated with the respective fully qualified host names of your managed machines and then specified at the command line by using `-i [inventory file name]`. [See the sample inventory file with more info at the base level of the repo, sample.hosts.](sample.hosts)

The second important file(s) that will be unique for each site's deployment are host variable files. [See the sample host variable file that contains all available options and info, host_vars/myhost.my.org.yml.](host_vars/myhost.my.org.yml) Note the format of the file name of any host variable file must be `host_vars/[hostname].yml`, where `[hostname]` matches with that specified in the inventory file. It is required to specify one for each host your site will be deploying to. Ansible will automatically find them and assign them to the respective hosts. More advanced users may like to review or revise variables within [group_vars](group_vars) to make their own modifications, see [Advice and Contributing](#advice-and-contributing).

### Examples

This section assumes the information in [Info](#info) is understood and the proper files have been created.

These examples are __not__ presented in a "step by step" style. Within reason, the commands outlined below can be performed at any point in the lifetime of a node. That being said, the *information* presented in earlier examples is requisite for later examples.

These examples are __not__ comprehensive, they only show common patterns and useful commands. Refer to the docs linked above and the `--help` flag for more information.
The primary command line tool used is `ansible-playbook`.
```
ansible-playbook --help
```

Although not discussed in this guide, the `ansible` command line tool can be useful as well.
```
ansible --help
```

It is recommended that users use the verbose flag `-v[v...]`, where each additional `v` adds more output.

#### Playbooks
Ansible uses 'playbooks' to define what actions to take on the managed machine(s). The primary playbook used is [install.yml](install.yml) for performing deployments. Other utility-like playbooks are outlined below as well.

#### SSH Authentication
Ansible assumes the use of keys for ssh authentication. It provides `--ask-pass` and `-u [user]` to ssh via password authentication. For escalated privileges, if sshing as a non-root user, `--ask-become-pass` is used to prompt for a sudo password. See [Ansible's examples](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html#your-first-commands) as well.
A test deployment to all managed test hosts, with ssh via the root user and password authentication.
```
ansible-playbook -v -i hosts.test --ask-pass -u root install.yml
```

A test deployment to all managed test hosts, with ssh via a non-root user, *joe*, that has sudo privileges on the managed machine(s).
```
ansible-playbook -v -i hosts.test --ask-pass -u joe --ask-become-pass install.yml
```

__*The authentication method of choice will also be required below.*__

#### Deployment Control
A production deployment to all managed production hosts.
```
ansible-playbook -v -i hosts.prod install.yml
```

A useful command for a data-only deployment or a deployment only to your data node
```
ansible-playbook -v -i hosts.test --tags data --limit host-data.my.org install.yml
```

If you have already done the `base` steps, the steps that are needed on every node type, and don't want to wait for them to be repeated
```
ansible-playbook -v -i hosts.test --skip-tags base install.yml
```
or, to only do the `base` steps on your idp and index node
```
ansible-playbook -v -i hosts.test --tags base --limit host-index-idp.my.org install.yml
```

Multiple tags can be specified at once, for example 
```
... --tags "data,idp" --skip-tags "base,index" ...
```

The tags available in the [install.yml](install.yml) play are: `base`, `idp`, `index`, and `data`.
These can be used with `--tags` and `--skip-tags` as well as with `--limit [hostname]` to control exactly what is done and where.

#### Starting and Stopping Services
Node services can be started or stopped using the [start.yml](start.yml) and [stop.yml](stop.yml) playbooks. In the examples below, start tags and stop tags are any combination of `[cog, slcs, myproxy, tomcat, solr, dashboard-ip, gridftp, httpd, postgres, monitoring, data, idp, index]`. These tags can also be used in any combination in `--skip-tags`.

By default, if no start tags are specified, all services will be started. The services `httpd`, `postgres` and `monitoring` will always be started, unless specified via `--skip-tags`. If no stop tags are specfied, all services, EXCEPT `httpd`, `postgres` and `monitoring`, will be stopped. The services `httpd`, `postgres` and `monitoring` will only be stopped if their respective tag is specified via `--tags`.
```
ansible-playbook -v -i hosts.test start.yml [ --tags "start tags" ]
ansible-playbook -v -i hosts.test stop.yml [ --tags "stop tags" ]
```

Multiple playbooks may be specfified and are executed in the order specified. For example, to restart `cog`, `slcs` and `myproxy`:
```
ansible-playbook -v -i hosts.test stop.yml start.yml --tags "cog, slcs, myproxy"
```

To start or stop a data-only node use `--limit [data node hostname]`. Only the common tags and those associated with data nodes will have an effect.
```
ansible-playbook -v -i hosts.test --limit host-data.my.org start.yml [ --tags "start tags" ]
ansible-playbook -v -i hosts.test --limit host-data.my.org stop.yml [ --tags "stop tags" ]
```

#### Local Certs
Globus certificates and keys, aka 'local certs', for globus services are retrieved as part of the post-install process. If not specified the the host's variable file, the deployment will place a private key and CSR for these services in the HOME directory of the root user on the node. Once signed and retrieved from an ESGF certificate authority, these can be specified in the host's variable file and installed using the [local_certs.yml](local_certs.yml) playbook.
```
ansible-playbook -v -i hosts.prod local_certs.yml
```
or, for data-only
```
ansible-playbook -v -i hosts.prod --limit host-data.my.org local_certs.yml
```

#### Web Certs
Certificates for web services may be installed independent from the primary installation process via the [web_certs.yml](web_certs.yml) playbook. See the sample host variable file to see how to specify what certifcate/key/cachain to install. This can be used to try to setup LetsEncrypt certificates as well. See the `try_letsencrypt` variable in the sample host variable file for more information.
```
ansible-playbook -v -i hosts.prod web_certs.yml
```

#### Solr Shards
A number of Solr shards are loaded as remote indicies. For improved load times these can be replicated locally. [shards.yml](shards.yml) is provided to ease this process.
```
ansible-playbook -v -i hosts.prod --extra-vars="remote_hostname=[remote host to replicate locally] local_port=[start at 8985 and increment]" --tags add shards.yml
```

If you would like to remove the replicated shard.
```
ansible-playbook -v -i hosts.prod --extra-vars="remote_hostname=[remote host replicated locally] local_port=[port used by replicated shard]" --tags remove shards.yml
```

## FAQ
__Q: How can I use this to upgrade my older node?__

Answer: Make sure you stop all services on your older node using the legacy tools for doing so. If there are valid certificates and keys in place on the machine that you would like to continue to use, put those in a place on your control machine and specify that path in your host variable file. Once you have filled your variable file(s) and your inventory file as described above, the same example commands above for doing clean installs can be used to perform the upgrade. While many considerations have been made for upgrades and the preservation of customizations, it is still recommended that users create backups of site-specific changes to their node.

__Q: Ansible is stuck on a task for a long period of time and doesn't seem to be doing anything.__

Answer: First, Ansible will not report the result, stdout and stderr of a task until the task is completed. Some tasks can take several minutes to complete. Second, make sure the verbose flag is specified, `-v`, to get more information upon the completion of tasks.

## Advice and Contributing

If your site would like to use more specific configuration files and options, or make large site-specific additions, it is encouraged that you fork this repository. If there are features you believe would benefit all sites that you would like to contribute, create a pull request.