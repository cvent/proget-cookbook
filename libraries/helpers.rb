# frozen_string_literal: true
include Windows::Helper

module ProgetCookbook
  module HelpersBase
    def current_version
      installed_packages.fetch('ProGet', {})[:version]
    end

    def strip_patch_version(version)
      version.split('.')[0...-1].join('.')
    end

    def to_camel_case(str)
      str.to_s.split('_').collect(&:capitalize).join
    end

    def to_snake_case(str)
      str.to_s
         .gsub(/([a-z])([A-Z])/, '\1_\2')
         .gsub(/([A-Z])([A-Z][a-z])/, '\1_\2')
         .downcase
    end

    def proget_url(sql, version)
      "https://inedo.com/proget/download/#{sql ? 'sql' : 'nosql'}/#{version}"
    end

    def install_args(resource)
      args = ['/S', "/Edition=#{to_camel_case(resource.edition)}"]

      args + %w(
        EmailAddress
        FullName
        LicenseKey
        TargetPath
        PackagesPath
        ASPNETTempPath
        WebAppPath
        ServicePath
        Extensions
        ConnectionString
        Port
        UseIntegratedWebServer
        WebServerPrefixes
        InstallSqlExpress
        UserAccount
        Password
        WebAppUserAccount
        WebAppUserAccountPassword
        ServiceUserAccount
        ServiceUserAccountPassword
        ConfigureIIS).map { |name| [name, resource.send(to_snake_case(name))] }
       .reject { |prop| prop[1].nil? }
       .map { |prop| format_arg(*prop) }
    end

    def upgrade_args(resource)
      args = ['/S', '/Upgrade']

      args + %w(
        BackupDatabase
        DatabaseBackupPath
        ConnectionString
        LogFile).map { |name| [name, resource.send(to_snake_case(name))] }
       .reject { |prop| prop[1].nil? }
       .map { |prop| format_arg(*prop) }
    end

    def format_arg(key, value)
      if [true, false].include?(value)
        "/#{key}=#{value}"
      else
        "/#{key}=\"#{value}\""
      end
    end
  end
end
