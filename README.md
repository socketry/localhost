# Localhost [![Build Status](https://travis-ci.com/socketry/localhost.svg)](https://travis-ci.com/socketry/localhost)

This gem provides a convenient API for generating per-user self-signed root certificates.

## Motivation

HTTP/2 requires SSL in web browsers. If you want to use HTTP/2 for development (and you should), you need to start using URLs like `https://localhost:8080`. In most cases, this requires adding a self-signed certificate to your certificate store (e.g. Keychain on macOS), and storing the private key for the web-server to use.

I wanted to provide a server-agnostic way of doing this, primarily because I think it makes sense to minimise the amount of junky self-signed keys you add to your certificate store for `localhost`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'localhost'
```

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install localhost

## Usage

This example shows how to generate a certificate for an SSL secured web server:

```ruby
require 'localhost/authority'

authority = Localhost::Authority.fetch

OpenSSL::SSL::SSLContext.new.tap do |context|
	context.cert = authority.certificate
	context.key = authority.key
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## See Also

- [falcon](https://github.com/socketry/falcon) — Uses this `Localhost::Authority` to provide HTTP/2 with minimal configuration for `localhost`.

## License

Released under the MIT license.

Copyright, 2018, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
