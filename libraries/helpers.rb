module ProgetCookbook
  module HelpersBase
    def current_version
      reg_entries = Chef::Provider::Package::Windows::RegistryUninstallEntry.find_entries('ProGet')
      case reg_entries.length
      when 0 then nil
      when 1 then Gem::Version.new(reg_entries[0].display_version)
      else raise 'Too many ProGet installs detected'
      end
    end

    def package_version(version)
      version.split('.')[0...-1].join('.')
    end

    def to_camel_case(str)
      str.to_s.split('_').collect(&:capitalize).join
    end

    def to_snake_case(str)
     str.to_s
        .gsub(/([a-z])([A-Z])/,'\1_\2')
        .gsub(/([A-Z])([A-Z][a-z])/, '\1_\2')
        .downcase
    end

    def proget_url(external_sql, version)
      "https://inedo.com/proget/download/#{external_sql ? 'nosql' : 'sql'}/#{version}"
    end

    def install_args(resource)
      args = ['/S', "/Edition=#{to_camel_case(resource.edition)}"]

      args += [
        'EmailAddress',
        'FullName',
        'LicenseKey',
        'TargetPath',
        'PackagesPath',
        'ASPNETTempPath',
        'WebAppPath',
        'ServicePath',
        'Extensions',
        'ConnectionString',
        'Port',
        'UseIntegratedWebServer',
        'WebServerPrefixes',
        'InstallSqlExpress',
        'UserAccount',
        'Password',
        'WebAppUserAccount',
        'WebAppUserAccountPassword',
        'ServiceUserAccount',
        'ServiceUserAccountPassword',
        'ConfigureIIS'
      ].map { |name| [name, resource.send(to_snake_case(name))] }
       .reject { |prop| prop[1].nil? }
       .map { |prop| [true, false].include?(prop[1]) ? "/#{prop[0]}=#{prop[1]}" : "/#{prop[0]}=\"#{prop[1]}\"" }
      args
    end

    def upgrade_args(resource)
      args = ['/S', '/Upgrade']

      args += [
        :connection_string,
        :log_file
      ].reject { |prop| resource.send(prop).nil? }
       .map { |prop| "/#{to_camel_case(prop)}=\"#{resource.send(prop)}\"" }
      args
    end
  end
end
