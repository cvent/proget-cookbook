# frozen_string_literal: true

# Does not work on appveyor as
# ls HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* |? { $_.PSChildName -eq 'ProGet' }
# does not work
# describe package('ProGet') do
#   it { should be_installed }
#   its('version') { should eq '4.4.1.30' }
# end

describe port(81) do
  it { should be_listening }
end

describe command("(curl 'http://localhost:81' -UseBasicParsing).Content") do
  its('stdout') { should match %r{<title>ProGet Home</title>} }
end
