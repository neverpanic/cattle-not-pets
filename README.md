# Cattle not Pets

This repository contains a Makefile and an example `butane.yml` that shows how
I provision my private infrastructure with Fedora CoreOS. The generated ISO
file will automatically install to `/dev/vda` (typically the first disk in
a VM) and will keep itself current with Fedora CoreOS' `zincati` auto-update
service.

This specific example deploys a [Traefik][traefik] reverse proxy in front of
a [Jellyfin][jellyfin] media server. I don't actually use this in production,
but it does serve as a good example.

Note that a few features that one might typically want in a production deployment are missing. In no particular order:

 - TLS support
 - TLS certificates using ACME, potentially using the DNS.01 challenge
 - proper configuration of the Traefik proxy in front of Jellyfin ([upstream docs][jellyfin-traefik])

## Resources

Further reading and references that will help you understand how these pieces fit together:

 - [Fedora CoreOS Documentation][coreos-docs]
 - [Butane configuration spec][butane-spec]
 - [Podman Quadlet Documentation][podman-quadlets]

## Problems

This method to set up VMs has a few problems you should be aware of.

### Secrets management
There is no secrets management. The generated ISO images contain the secrets in
plain text and must therefore be kept private. The [upstream
recommendation][secrets-mgmt] is to obtain the secrets after the initial boot
from a secret management service, e.g., Hashicorp Vault, or deploy them after
initial setup using Ansible.

### Installing additional packages
Installing additional packages on Fedora CoreOS is cumbersome. It can be done
using a specialized systemd unit that ends with a reboot, and that's what this
`butane.yml` implements (but doesn't use, because this example does not require
it). [Fedora's docs][installing-fedora], [coreos/butane#81][installing-butane],
and [coreos/fedora-coreos-tracker#681][installing-coreos] cover the problem and
discuss potential solution (among them the one I am using here).

Using [bootable containers][bootc] may solve this, because you can just perform
the package installation steps in your `Containerfile`.

[traefik]: https://doc.traefik.io/traefik/
[jellyfin]: https://jellyfin.org/
[jellyfin-traefik]: https://jellyfin.org/docs/general/post-install/networking/advanced/traefik/
[coreos-docs]: https://docs.fedoraproject.org/en-US/fedora-coreos/
[butane-spec]: https://coreos.github.io/butane/specs/
[podman-quadlets]: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html
[secrets-mgmt]: https://coreos.github.io/ignition/operator-notes/#secrets
[installing-fedora]: https://docs.fedoraproject.org/en-US/fedora-coreos/os-extensions/#_example_layering_vim_and_setting_it_as_the_default_editor
[installing-butane]: https://github.com/coreos/butane/issues/81
[installing-coreos]: https://github.com/coreos/fedora-coreos-tracker/issues/681
[bootc]: https://docs.fedoraproject.org/en-US/bootc/getting-started/
