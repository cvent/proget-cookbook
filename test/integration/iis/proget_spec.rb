# frozen_string_literal: true

describe package('ProGet') do
  it { should be_installed }
  its('version') { should eq '4.4.1.30' }
end

describe iis_site('ProGet') do
  it { should exist }
  it { should be_running }
  it { should have_app_pool('ProGetAppPool') }
end

describe port(81) do
  it { should be_listening }
end

describe command("(curl 'http://localhost:81' -UseBasicParsing).Content") do
  its('stdout') { should match %r{<title>ProGet Home</title>} }
end
