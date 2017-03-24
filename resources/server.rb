# frozen_string_literal: true

property :name, String, name_property: true
property :version, String, required: true
property :package_version, String, default: lazy { strip_patch_version(version) }
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
property :port, Integer, default: 81
property :use_integrated_web_server, [true, false], default: true
property :web_server_prefixes, String
# We default to true here so that the defaults will install a
# self-contained ProGet instance
property :install_sql_express, [true, false], default: true
property :user_account, String
property :password, String
property :web_app_user_account, String
property :web_app_user_account_password, String
property :service_user_account, String
property :service_user_account_password, String
property :log_file, String
property :configure_iis, [true, false], default: lazy { !use_integrated_web_server }

property :iis, [true, false], default: lazy { !use_integrated_web_server }

property :backup_database, [true, false]
property :database_backup_path, String

include ProgetCookbook::HelpersBase

default_action :install

action :install do
  validate_props(new_resource)

  action_iis if new_resource.iis

  args = case current_version
         when nil
           install_args(new_resource)
         when ->(v) { Gem::Version.new(v) < Gem::Version.new(new_resource.version) }
           upgrade_args(new_resource)
         end

  package_cache_dir = Chef::FileCache.create_cache_path('package')
  package 'ProGet' do # ~FC009
    action :install
    source proget_url(install_sql_express, package_version)
    checksum new_resource.checksum if new_resource.checksum
    remote_file_attributes name: ::File.join(package_cache_dir, "proget-#{package_version}.exe")
    version new_resource.version
    installer_type :custom
    options args.join(' ')
    notifies :run, "ruby_block[#{new_resource.name} install failure]", :immediately
    notifies :run, "ruby_block[wait for #{new_resource.name}]", :immediately
  end if args

  ruby_block "#{new_resource.name} install failure" do
    action :nothing
    block { raise 'Installation of Proget failed' }
    not_if { current_version == new_resource.version }
  end

  ruby_block "wait for #{new_resource.name}" do
    action :nothing
    block do
      require 'net/http'

      test_server = lambda do
        begin
          Net::HTTP.get_response('localhost', '/', new_resource.port).is_a?(Net::HTTPSuccess)
        rescue
          false
        end
      end

      until test_server.call
        Chef::Log.info "Waiting for #{new_resource.name} to be up"
        sleep 2
      end
    end
  end
end

action :remove do
  package 'ProGet' do # ~FC009
    action :remove
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

def validate_props(resource)
  case resource.edition
  when :express, :trial
    raise "email_address required for #{edition} licences" unless resource.email_address
    raise "full_name required for #{edition} licences" unless resource.full_name
  when :license_key
    raise "license_key required for #{license_type} licences" unless resource.license_key
  end
end
