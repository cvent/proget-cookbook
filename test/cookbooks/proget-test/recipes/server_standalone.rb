proget_server 'proget' do
  action :install
  edition :express
  email_address 'jmorley@cvent.com'
  full_name 'JonathanMorley'
  version '4.4.1'
  package_version '4.4.1.30'
  iis false
end

# TODO: Check for ProGet to be up
ruby_block 'wait for ProGet' do
  block do
    sleep 10
  end
end
