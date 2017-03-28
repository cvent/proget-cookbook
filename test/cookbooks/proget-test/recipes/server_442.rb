# frozen_string_literal: true

proget_server 'proget' do
  action :install
  edition :express
  email_address 'example@example.com'
  full_name 'Example'
  version '4.4.2.5'
end
