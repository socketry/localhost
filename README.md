# Localhost

This gem provides a convenient API for generating per-user self-signed root certificates.

[![Build Status](https://travis-ci.com/socketry/localhost.svg)](https://travis-ci.com/socketry/localhost)
[![Coverage Status](https://coveralls.io/repos/socketry/localhost/badge.svg)](https://coveralls.io/r/socketry/localhost)

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

This example shows how to generate a certificate for an SSL secured server:

```ruby
require 'socket'
require 'thread'

require 'localhost/authority'

# Get the self-signed authority for localhost:
authority = Localhost::Authority.fetch

ready = Thread::Queue.new

# Start a server thread:
server_thread = Thread.new do
	server = OpenSSL::SSL::SSLServer.new(TCPServer.new("localhost", 4050), authority.server_context)
	
	server.listen
	
	ready << true
	
	peer = server.accept
	
	peer.puts "Hello World!"
	peer.flush
	
	peer.close
end

ready.pop

client = OpenSSL::SSL::SSLSocket.new(TCPSocket.new("localhost", 4050), authority.client_context)

# Initialize SSL connection:
client.connect

# Read the encrypted message:
puts client.read(12)

client.close
server_thread.join
```

If you use Safari to access such a server, it will allow you to add the certificate to your keychain without much work. Once you've done this, you won't need to do it again for any other site when running such a development environment from the same user account.

For an example of how to make your own HTTPS web server, see [examples/https.rb](examples/https.rb).

### Safari

If you use this with a web server, when you open the site in Safari:

![Safari](media/safari.png)

- Click "View the certificate" to check that it is the correct certificate.
- Click "visit this website" which will prompt you to add the certificate to your keychain. Once you've done this, it should work for a long time.

### Chrome

If you use this with a web server, when you open the site in Chrome:

![Chrome](media/chrome.png)

- Click "ADVANCED" to see additional details, including...
- Click "Proceed to localhost (unsafe)" which will allow you to use the site for the current browser session.

#### Self-Signed Localhost

The best way to use Chrome wiht self-signed localhost certificates is to allow it in your chrome settings: [chrome://flags/#allow-insecure-localhost](chrome://flags/#allow-insecure-localhost).

### Files

The certificate and private key are stored in `~/.localhost/`. You can delete them and they will be regenerated. If you added the certificate to your keychain, you'll probably want to delete that too.

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
