# Localhost

This gem provides a convenient API for generating per-user self-signed root certificates.

[![Development Status](https://github.com/socketry/localhost/workflows/Test/badge.svg)](https://github.com/socketry/localhost/actions?workflow=Test)

## Motivation

HTTP/2 requires SSL in web browsers. If you want to use HTTP/2 for development (and you should), you need to start using URLs like `https://localhost:8080`. In most cases, this requires adding a self-signed certificate to your certificate store (e.g. Keychain on macOS), and storing the private key for the web-server to use.

I wanted to provide a server-agnostic way of doing this, primarily because I think it makes sense to minimise the amount of junky self-signed keys you add to your certificate store for `localhost`.

## Usage

Please see the [project documentation](https://socketry.github.io/localhost/).

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

## See Also

  - [Falcon](https://github.com/socketry/falcon) — Uses `Localhost::Authority` to provide HTTP/2 with minimal configuration.
  - [Puma](https://github.com/puma/puma) — Supports `Localhost::Authority` to provide self-signed HTTP for local development.
