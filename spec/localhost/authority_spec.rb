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
require 'fileutils'

RSpec.describe Localhost::Authority do
	it "can generate key and certificate" do
		FileUtils.mkdir_p("ssl")
		subject.save("ssl")
		
		expect(File).to be_exist("ssl/localhost.lock")
		expect(File).to be_exist("ssl/localhost.crt")
		expect(File).to be_exist("ssl/localhost.key")
	end
	
	it "have correct key and certificate path" do
		subject.save(subject.class.path)
		expect(File).to be_exist(subject.certificate_path)
		expect(File).to be_exist(subject.key_path)

		expect(subject.key_path).to eq(File.join(File.expand_path("~/.localhost"), "localhost.key"))
		expect(subject.certificate_path).to eq(File.join(File.expand_path("~/.localhost"), "localhost.crt"))
	end

	describe '#store' do
		it "can verify certificate" do
			expect(subject.store.verify(subject.certificate)).to be true
		end
	end
	
	describe '#server_context' do
		it "can generate appropriate ssl context" do
			expect(subject.server_context).to be_a OpenSSL::SSL::SSLContext
		end
	end
	
	context 'client/server' do
		include_context Async::RSpec::Reactor
		
		let(:endpoint) {Async::IO::Endpoint.tcp("localhost", 4040)}
		let!(:server_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: subject.server_context)}
		let!(:client_endpoint) {Async::IO::SSLEndpoint.new(endpoint, ssl_context: subject.client_context)}
		
		let(:client) {client_endpoint.connect}
		
		it "can verify peer" do
			server_task = reactor.async do
				server_endpoint.accept do |peer|
					peer.write("Hello World!")
					peer.close
				end
			end
			
			expect(client.read(12)).to be == "Hello World!"
			
			client.close
			server_task.stop
		end
	end
end
