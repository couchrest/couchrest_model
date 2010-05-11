
# require File.join(File.dirname(__FILE__), "couchrest", "extended_document")

gem 'samlown-couchrest'

require 'couchrest'

require 'active_support'
require 'mime/types'
require "enumerator"

# Monkey patches applied to couchrest
require File.join(File.dirname(__FILE__), 'couchrest', 'support', 'couchrest')

# Base libraries
require File.join(File.dirname(__FILE__), 'couchrest', 'extended_document')
require File.join(File.dirname(__FILE__), 'couchrest', 'casted_model')

# Add rails support *after* everything has loaded
require File.join(File.dirname(__FILE__), 'couchrest', 'support', 'rails') if defined?(Rails)

