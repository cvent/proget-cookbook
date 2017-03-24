proget_server 'proget' do
  action :install
  edition :express
  email_address 'example@example.com'
  full_name 'Example'
  version '4.4.1.30'
end

# TODO: Check for ProGet to be up
ruby_block 'wait for ProGet' do
  block do
    sleep 10
  end
end
