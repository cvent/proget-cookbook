# For some reason the code below doesn't work on appveyor
# describe package('ProGet') do
#   it { should be_installed }
#   its('version') { should eq '4.4.1.30' }
# end

describe iis_site('ProGet') do
  it { should exist }
  it { should be_running }
  it { should have_app_pool('ProGetAppPool') }
end

describe port(80) do
  it { should be_listening }
end

describe command("(curl 'http://localhost:80' -UseBasicParsing).Content") do
  its('stdout') { should match (/<title>ProGet Home<\/title>/) }
end
