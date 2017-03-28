# frozen_string_literal: true

node.default['sql_server']['accept_eula'] = true
node.default['sql_server']['server_sa_password'] = '<enterStrongPasswordHere>'

include_recipe 'sql_server::server'

reboot 'sql server install' do
  action :cancel
end

proget_server 'proget' do
  action :install
  edition :express
  email_address 'example@example.com'
  full_name 'Example'
  version '4.4.1.30'
  install_sql_express false
end
