This is a collection of examples of how to deploy web services and managing the machines they run on.

# Examples

The examples include the following features:

- `http`: Configures an HTTP service. (Note that HTTP is not encrypted. Use HTTPS instead for anything that requires encryption.)

Coming soon:

- `https`: Configures an HTTPS service, including renewing certificates with [Let's Encrypt](https://letsencrypt.org/).
- `ssh`: Allows you to check on a running machine. Useful for investigating issues with services or looking at logs.
- `vpn`: Sets up a virtual private network. Useful for private things you want to access from anywhere.

# Targets

There are several ways of deploying the examples on machines:

- `local-vm`: Runs a configuration in a virtual machine on this host. Good for experimenting; saves you from buying or renting a machine.
- `iso-installer`: Creates an installation medium that installs NixOS and the custom configuration. Saves you from having to install some default configuration first.

Coming soon:

- `tf`: For managing rented machines declaratively.

See `./profiles` and the respective `./profiles/*/README.md` for details.
