property :name, String, name_property: true
property :edition, [:express, :trial, :license_key], required: true
property :email_address, String
property :full_name, String
property :license_key, String
property :version, String, required: true
property :package_version, String, default: lazy { version }
property :checksum, String
property :port, Fixnum, default: 80
property :iis, [true, false], default: false
property :connection_string, String
property :target_path, String
property :packages_path, String
property :log_file, String

# Details on these flags, their meanings and defaults can be found at
# http://inedo.com/support/documentation/proget/installation/silent-installation

action :install do
  case edition
  when :express, :trial
    raise "email_address required for #{edition} licences" unless email_address
    raise "full_name required for #{edition} licences" unless full_name
  when :license_key
    raise "license_key required for #{license_type} licences" unless license_key
  end

  install_args = ['/S', "/Edition=#{camel_case(edition)}"]

  install_args += [
    :email_address,
    :full_name,
    :license_key,
    :packages_path,
    :port,
    :log_file,
    :connection_string,
    :target_path
  ].reject { |prop| new_resource.send(prop).nil? }
   .map { |prop| "/#{camel_case(prop)}=#{new_resource.send(prop)}" }

  install_args << '/InstallSqlExpress' unless connection_string
  install_args << "/UseIntegratedWebServer=#{!iis}"
  install_args << "/ConfigureIIS=#{iis}"

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

  package 'ProGet' do
    action :install
    source proget_installer
    version new_resource.version
    installer_type :custom
    options install_args.join(' ')
  end
end

# Untested
action :upgrade do
  upgrade_args = ['/S', '/Upgrade']

  install_args += [
    :connection_string,
    :log_file
  ].reject { |prop| new_resource.send(prop).nil? }
   .map { |prop| "/#{camel_case(prop)}=#{new_resource.send(prop)}" }

  package_cache_dir = Chef::FileCache.create_cache_path('package')
  proget_installer = ::File.join(package_cache_dir, "proget-#{new_resource.version}.exe")

  remote_file proget_installer do
    source proget_url(connection_string, new_resource.version)
    checksum new_resource.checksum if new_resource.checksum
  end

  package 'ProGet' do
    action :install
    source proget_installer
    version new_resource.version
    installer_type :custom
    options args.join(' ')
  end
end

def camel_case(str)
  str.to_s.split('_').collect(&:capitalize).join
end

def proget_url(external_sql, version)
  "http://inedo.com/proget/download/#{external_sql ? 'nosql' : 'sql'}/#{version}"
end
