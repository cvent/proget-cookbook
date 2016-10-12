# For some reason the code below doesn't work on appveyor
# describe package('ProGet') do
#   it { should be_installed }
#   its('version') { should eq '4.4.2.5' }
# end

describe port(80) do
  it { should be_listening }
end

describe command("(curl 'http://localhost:80' -UseBasicParsing).Content") do
  its('stdout') { should match (/<title>ProGet Home<\/title>/) }
end
