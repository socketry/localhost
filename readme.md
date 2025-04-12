# Localhost

This gem provides a convenient API for generating per-user self-signed root certificates.

[![Development Status](https://github.com/socketry/localhost/workflows/Test/badge.svg)](https://github.com/socketry/localhost/actions?workflow=Test)

## Motivation

HTTP/2 requires SSL in web browsers. If you want to use HTTP/2 for development (and you should), you need to start using URLs like `https://localhost:8080`. In most cases, this requires adding a self-signed certificate to your certificate store (e.g. Keychain on macOS), and storing the private key for the web-server to use.

I wanted to provide a server-agnostic way of doing this, primarily because I think it makes sense to minimise the amount of junky self-signed keys you add to your certificate store for `localhost`.

## Usage

Please see the [project documentation](https://socketry.github.io/localhost/) for more details.

  - [Getting Started](https://socketry.github.io/localhost/guides/getting-started/index) - This guide explains how to use `localhost` for provisioning local TLS certificates for development.

  - [Example Server](https://socketry.github.io/localhost/guides/example-server/index) - This guide demonstrates how to use <code class="language-ruby">Localhost::Authority</code> to implement a simple HTTPS client & server.

## Releases

Please see the [project releases](https://socketry.github.io/localhost/releases/index) for all releases.

### v1.4.0

  - Add `localhost:purge` to delete all certificates.
  - Add `localhost:install` to install the issuer certificate in the local trust store.

## See Also

  - [Falcon](https://github.com/socketry/falcon) — Uses `Localhost::Authority` to provide HTTP/2 with minimal configuration.
  - [Puma](https://github.com/puma/puma) — Supports `Localhost::Authority` to provide self-signed HTTP for local development.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
