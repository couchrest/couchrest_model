gem 'couchrest', ">= 1.0.0"
require 'couchrest'

gem "tzinfo", ">= 0.3.22"

gem 'railties', ">= 3.0.0.rc"
gem "activesupport", ">= 3.0.0.rc"

require 'active_support/core_ext'
require 'active_support/json'

gem "activemodel", ">= 3.0.0.rc"
require 'active_model'
require "active_model/callbacks"
require "active_model/conversion"
require "active_model/deprecated_error_methods"
require "active_model/errors"
require "active_model/naming"
require "active_model/serialization"
require "active_model/translation"
require "active_model/validator"
require "active_model/validations"

gem "mime-types", ">= 1.15"
require 'mime/types'
require "enumerator"
require "time"
require 'digest/md5'

require 'bigdecimal' # used in typecast
require 'bigdecimal/util' # used in typecast

require 'couchrest/model'
require 'couchrest/model/errors'
require "couchrest/model/persistence"
require "couchrest/model/typecast"
require "couchrest/model/property"
require "couchrest/model/casted_array"
require "couchrest/model/properties"
require "couchrest/model/validations"
require "couchrest/model/callbacks"
require "couchrest/model/document_queries"
require "couchrest/model/views"
require "couchrest/model/design_doc"
require "couchrest/model/extended_attachments"
require "couchrest/model/class_proxy"
require "couchrest/model/collection"
require "couchrest/model/attribute_protection"
require "couchrest/model/associations"
require "couchrest/model/configuration"

# Monkey patches applied to couchrest
require "couchrest/model/support/couchrest"
require "couchrest/model/support/hash"

# Base libraries
require "couchrest/model/casted_model"
require "couchrest/model/base"

# Add rails support *after* everything has loaded

require "couchrest/railtie"
