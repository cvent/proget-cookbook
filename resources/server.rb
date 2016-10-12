property :name, String, name_property: true
property :version, String, required: true
property :package_version, String, default: lazy { version }
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
property :port, Fixnum, default: 80
property :web_server_prefixes, String
property :user_account, String
property :password, String
property :web_app_user_account, String
property :web_app_user_account_password, String
property :service_user_account, String
property :service_user_account_password, String
property :log_file, String

property :iis, [true, false], default: false

property :backup_database, [true, false]
property :database_backup_path

default_action :install

action :install do
  case edition
  when :express, :trial
    raise "email_address required for #{edition} licences" unless email_address
    raise "full_name required for #{edition} licences" unless full_name
  when :license_key
    raise "license_key required for #{license_type} licences" unless license_key
  end

  installer_args = case current_version
                   when nil
                     installer_args = ['/S', "/Edition=#{camel_case(edition)}"]

                     installer_args += [
                       :email_address,
                       :full_name,
                       :license_key,
                       :target_path,
                       :packages_path,
                       :aspnet_temp_path,
                       :web_app_path,
                       :service_path,
                       :extensions,
                       :connection_string,
                       :port,
                       :web_server_prefixes,
                       :user_account,
                       :password,
                       :web_app_user_account,
                       :web_app_user_account_password,
                       :service_user_account,
                       :service_user_account_password,
                       :log_file
                     ].reject { |prop| new_resource.send(prop).nil? }
                                       .map { |prop| "/#{camel_case(prop)}=#{new_resource.send(prop)}" }

                     installer_args << '/InstallSqlExpress' unless connection_string
                     installer_args << "/UseIntegratedWebServer=#{!iis}"
                     installer_args << "/ConfigureIIS=#{iis}"
                   when ->(v) { v < Gem::Version.new(package_version) }
                     installer_args = ['/S', '/Upgrade']

                     installer_args += [
                       :connection_string,
                       :log_file
                     ].reject { |prop| new_resource.send(prop).nil? }
                                       .map { |prop| "/#{camel_case(prop)}=#{new_resource.send(prop)}" }
                   else
                     return
                   end

  if iis
    include_recipe 'iis'
    include_recipe 'iis::remove_default_site'
    include_recipe 'iis::mod_aspnet45'

    # Unlock handlers
    iis_section 'unlock handlers' do
      action :unlock
      section 'system.webServer/handlers'
    end
  end

  package_cache_dir = Chef::FileCache.create_cache_path('package')
  proget_installer = ::File.join(package_cache_dir, "proget-#{new_resource.version}.exe")

  remote_file proget_installer do
    source proget_url(connection_string, new_resource.version)
    checksum new_resource.checksum if new_resource.checksum
  end

  package 'ProGet' do # ~FC009
    action :install
    source proget_installer
    version new_resource.version
    installer_type :custom
    options installer_args.join(' ')
  end
end

def current_version
  reg_entries = Chef::Provider::Package::Windows::RegistryUninstallEntry.find_entries('ProGet')
  case reg_entries.length
  when 0 then nil
  when 1 then Gem::Version.new(reg_entries[0].display_version)
  else raise 'Too many ProGet installs detected'
  end
end

def camel_case(str)
  str.to_s.split('_').collect(&:capitalize).join
end

def proget_url(external_sql, version)
  "http://inedo.com/proget/download/#{external_sql ? 'nosql' : 'sql'}/#{version}"
end
