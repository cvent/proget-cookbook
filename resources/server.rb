property :name, String, name_property: true
property :version, String, required: true
property :checksum, String

# Details on these flags, their meanings and defaults can be found at
# http://inedo.com/support/documentation/proget/installation/silent-installation

property :edition, [:express, :trial, :license_key], required: true
property :email_address, String
property :full_name, String
property :license_key, String
property :target_path, String
property :packages_path, String
property :aspnet_temp_path, String
property :web_app_path, String
property :service_path, String
property :extensions, String
property :connection_string, String
property :port, Fixnum
property :use_integrated_web_server, [true, false], default: true
property :web_server_prefixes, String
property :install_sql_express, [true, false], default: false
property :user_account, String
property :password, String
property :web_app_user_account, String
property :web_app_user_account_password, String
property :service_user_account, String
property :service_user_account_password, String
property :log_file, String
property :configure_iis, [true, false], default: lazy { !use_integrated_web_server }

property :iis, [true, false], default: lazy { !use_integrated_web_server }
property :sqlserver, [true, false], default: lazy { !install_sql_express }

property :backup_database, [true, false]
property :database_backup_path

include ProgetCookbook::HelpersBase
include Windows::Helper

default_action :install

action :install do
  validate_props(new_resource)

  action_iis if new_resource.iis
  action_sqlserver if new_resource.sqlserver

  package_cache_dir = Chef::FileCache.create_cache_path('package')
  package_version = package_version(new_resource.version)
  installed_version = installed_packages.fetch('ProGet', {})['version']
  p installed_version
  p install_args(new_resource).join(' ')
  package 'ProGet' do # ~FC009
    action :install
    source proget_url(connection_string, package_version)
    checksum new_resource.checksum if new_resource.checksum
    remote_file_attributes name: ::File.join(package_cache_dir, "proget-#{package_version}.exe")
    version new_resource.version
    installer_type :custom
    options install_args(new_resource).join(' ')
    notifies :run, 'ruby_block[raise for failure]', :immediately
  end

  ruby_block 'raise for failure' do
    block do
      raise 'Installation of Proget failed'
    end
    not_if { installed_packages.fetch('ProGet', {})['version'] }
  end
end

action :iis do
  include_recipe 'iis'
  include_recipe 'iis::mod_aspnet45'

  # Unlock handlers
  iis_section 'unlock handlers' do
    action :unlock
    section 'system.webServer/handlers'
  end
end

action :sqlserver do
end

def validate_props(resource)
  case resource.edition
  when :express, :trial
    raise "email_address required for #{edition} licences" unless resource.email_address
    raise "full_name required for #{edition} licences" unless resource.full_name
  when :license_key
    raise "license_key required for #{license_type} licences" unless resource.license_key
  end
end
