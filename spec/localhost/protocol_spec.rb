# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'localhost/authority'

require 'async/io/host_endpoint'
require 'async/io/ssl_endpoint'

require 'async/process'

RSpec.shared_examples_for "valid protocol" do |protocol|
	it "can connect using #{protocol}" do
		status = Async::Process.spawn("openssl", "s_client", "-connect", "localhost:4040", "-#{protocol}")
		
		expect(status).to be_success
		
		server_task.stop
	end
end

RSpec.shared_examples_for "invalid protocol" do |protocol|
	it "can connect using #{protocol}" do
		status = Async::Process.spawn("openssl", "s_client", "-connect", "localhost:4040", "-#{protocol}")
		
		expect(status).to_not be_success
		
		server_task.stop
	end
end

RSpec.describe Localhost::Authority do
	include_context Async::RSpec::Reactor
	
	let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 4040)}
	let(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: subject.server_context)}
	let(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: subject.client_context)}
	
	let(:client) {client_endpoint.connect}
	
	let!(:server_task) do
		reactor.async do
			server_endpoint.accept do |peer|
				peer.write("Hello World!")
				peer.close
			end
		end
	end
	
	it_behaves_like "invalid protocol", "ssl3"
	it_behaves_like "valid protocol", "tls1"
	it_behaves_like "valid protocol", "tls1_1"
	it_behaves_like "valid protocol", "tls1_2"
end
