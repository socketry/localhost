
require 'fileutils'
require 'localhost/authority'

RSpec.describe Localhost::Authority do
	it "can generate key and certificate" do
		FileUtils.mkdir_p("ssl")
		subject.save("ssl")
		
		expect(File).to be_exist("ssl/localhost.crt")
		expect(File).to be_exist("ssl/localhost.key")
	end
end
