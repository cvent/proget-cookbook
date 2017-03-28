# frozen_string_literal: true

proget_server 'proget' do
  action :install
  edition :express
  email_address 'example@example.com'
  full_name 'Example'
  version '4.4.1.30'
  use_integrated_web_server false
end
