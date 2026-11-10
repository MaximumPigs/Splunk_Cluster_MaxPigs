# Splunk_Cluster_MaxPigs

EC2 nodes for a Splunk cluster on the
[Maximumpigs_AWS_Fabric](https://github.com/MaximumPigs/Maximumpigs_AWS_Fabric)
baseline, built with [TF_Modules_AWS](https://github.com/MaximumPigs/TF_Modules_AWS).
Terraform creates the instances, DNS records and front-end load balancer;
Ansible configures Splunk.

| File | Contents |
| --- | --- |
| `fabric.tf` | Baseline lookups (TF_Modules_AWS `vpc` module, pinned tag) |
| `main.tf` | Node counts per role and one `ec2` module call per role |
| `security_groups.tf` | HTTP/HTTPS groups, open to trusted IPs only |
| `loadbalance.tf` | Network load balancer, TLS certificate and DNS (TODO: rework as ALB) |
| `cloudinit/userdata.tmpl` | First-boot cloud-init for every node |
| `tests/` | Plan-only unit tests with a mocked provider and mocked baseline |

## How it uses the baseline

- **Subnet:** every node runs in the ap-southeast-2a public subnet (no NAT gateway).
- **Security group:** nodes and the load balancer use the Fabric `baseline` group
  (trusted IPs, intra-VPC, outbound). Extra rules source the Fabric trusted-IP
  prefix list, so nothing is open to the internet.
- **DNS:** each node gets `<name>.aws.maximumpigs.com` in the private and public zones.
- **IAM:** nodes use `Generic_EC2_Role`, which includes Session Manager, so no SSH key is needed.
- **IMDSv2:** required on every node (ec2 module default).

## Prerequisites

1. Maximumpigs_AWS_Fabric applied with the security uplift (baseline security
   group and trusted prefix list exist). The plan fails with a clear message
   otherwise.
2. TF_Modules_AWS tagged `v2.0.0` (the release these sources pin).

## Usage

```sh
terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan
```

Optional variables: `aws_account_id` (refuse other accounts) and `key_pair`
(SSH key pair; not needed with Session Manager).

## First apply after the module uplift

Expect in-place updates only:

- every instance: `http_tokens` becomes `required`, the security group changes
  from the VPC default group to the Fabric baseline group, tags gain
  `Project`/`Repository`
- load balancer: security group changes to the baseline group
- HTTP/HTTPS rules: source changes from `0.0.0.0/0` to the trusted prefix list
- `allow_https` is replaced (description fixed; it is not attached to anything)

**Stop if any `aws_instance` shows "must be replaced".** A warning that a root
volume is not encrypted is expected for nodes built before EBS encryption by
default was enabled; encrypting them means rebuilding those nodes.

Anything on the nodes that only speaks IMDSv1 loses access to instance
metadata. Recent AWS CLIs and SDKs use IMDSv2.

## Cost

The network load balancer is billed hourly whether or not it has targets,
plus one public IPv4 address per subnet. With `searchhead_count` and
`heavyforwarder_count` at 0 it carries no traffic.

## Checks

TF_Modules_AWS is a private repository, so CI needs the Actions secret
`TF_MODULES_READ_TOKEN` to download it: a fine-grained personal access token
with access to TF_Modules_AWS only and **Contents: Read-only**. Renew it before
it expires.

CI runs these on every pull request:

```sh
terraform fmt -check -recursive
terraform init -backend=false && terraform validate
terraform test
tflint --init && tflint --recursive
checkov -d .
```
