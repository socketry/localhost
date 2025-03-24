# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.
# Copyright, 2021, by Ye Lin Aung.
# Copyright, 2024, by Colin Shea.
# Copyright, 2024, by Aurel Branzeanu.

require "localhost/authority"

require "sus/fixtures/async/reactor_context"
require "io/endpoint/ssl_endpoint"

require "fileutils"
require "tempfile"

describe Localhost::Authority do
	def around
		Dir.mktmpdir do |path|
			@root = path
			
			super
		ensure
			@root = nil
		end
	end
	
	let(:authority) {subject.new("localhost", path: @root)}
	
	it "have correct key and certificate path" do
		authority.save
		
		expect(File).to be(:exist?, authority.certificate_path)
		expect(File).to be(:exist?, authority.key_path)
		
		expect(File).to be(:exist?, File.expand_path("localhost.lock", @root))
		expect(File).to be(:exist?, File.expand_path("localhost.crt", @root))
		expect(File).to be(:exist?, File.expand_path("localhost.key", @root))
	end
	
	with "#certificate" do
		it "is not valid for more than 1 year" do
			certificate = authority.certificate
			validity = certificate.not_after - certificate.not_before
			
			# https://support.apple.com/en-us/102028
			expect(validity).to be <= 398 * 24 * 60 * 60
		end
	end
	
	with "#dh_key" do
		it "is a DH key" do
			expect(authority.dh_key).to be_a OpenSSL::PKey::DH
		end
	end
	
	with "#subject" do
		it "can get subject" do
			expect(authority.subject.to_s).to be == "/O=localhost.rb/CN=localhost"
		end
		
		it "can set subject" do
			authority.subject = OpenSSL::X509::Name.parse("/CN=example.localhost")
			expect(authority.subject.to_s).to be == "/CN=example.localhost"
		end
	end
	
	with "#key" do
		it "is an RSA key" do
			expect(authority.key).to be_a OpenSSL::PKey::RSA
		end
		
		it "can set key" do
			# Avoid generating a key, it's slow...
			# key = OpenSSL::PKey::RSA.new(1024)
			key = authority.key
			
			authority.key = key
			expect(authority.key).to be_equal(key)
		end
	end
	
	with "#store" do
		it "can verify certificate" do
			expect(authority.store.verify(authority.certificate)).to be == true
		end
	end
	
	with "#server_context" do
		it "can generate appropriate ssl context" do
			expect(authority.server_context).to be_a OpenSSL::SSL::SSLContext
		end
	end
	
	with ".list" do
		before do
			authority.save
		end
		
		it "can list all authorities" do
			authorities = Localhost::Authority.list(@root).to_a
			
			expect(authorities.size).to be == 1
			expect(authorities.first).to be_a Localhost::Authority
			expect(authorities.first).to have_attributes(
				hostname: be == "localhost",
			)
		end
	end
	
	with ".fetch" do
		def before
			super
			
			authority.save
		end
		
		it "can fetch existing authority" do
			fetched_authority = Localhost::Authority.fetch("localhost", path: @root)
			expect(fetched_authority).to have_attributes(
				hostname: be == "localhost",
			)
		end
		
		it "can create new authority" do
			fetched_authority = Localhost::Authority.fetch("example.com", path: @root)
			expect(fetched_authority).to have_attributes(
				hostname: be == "example.com",
			)
			
			expect(File).to be(:exist?, fetched_authority.certificate_path)
			expect(File).to be(:exist?, fetched_authority.key_path)
		end
	end
end
