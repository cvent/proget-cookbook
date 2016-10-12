describe package('ProGet') do
  it { should be_installed }
  its('version') { should eq '4.4.2.5' }
end

describe port(80) do
  it { should be_listening }
end
