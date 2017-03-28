# frozen_string_literal: true
name 'proget'
maintainer 'Morley, Jonathan'
maintainer_email 'JMorley@cvent.com'
license 'Apache 2.0'
description 'Handles installing ProGet Server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url 'https://github.com/cvent/proget-cookbook'
issues_url 'https://github.com/cvent/proget-cookbook/issues'
version '0.1.0'

supports 'windows'

depends 'iis'
depends 'windows'
