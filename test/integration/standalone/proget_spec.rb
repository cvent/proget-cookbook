describe package('ProGet') do
  it { should be_installed }
end

describe port(80) do
  it { should be_listening }
end
