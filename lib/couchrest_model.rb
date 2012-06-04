require 'active_model'
require "active_model/callbacks"
require "active_model/conversion"
require "active_model/errors"
require "active_model/naming"
require "active_model/serialization"
require "active_model/translation"
require "active_model/validator"
require "active_model/validations"
require "active_model/dirty"

require 'active_support/core_ext'
require 'active_support/json'

require 'mime/types'
require "enumerator"
require "time"
require 'digest/md5'

require 'bigdecimal' # used in typecast
require 'bigdecimal/util' # used in typecast

require 'couchrest'

require 'couchrest/model'
require 'couchrest/model/errors'
require "couchrest/model/persistence"
require "couchrest/model/typecast"
require "couchrest/model/casted_by"
require "couchrest/model/dirty"
require "couchrest/model/property"
require "couchrest/model/property_protection"
require "couchrest/model/properties"
require "couchrest/model/casted_array"
require "couchrest/model/casted_hash"
require "couchrest/model/validations"
require "couchrest/model/callbacks"
require "couchrest/model/document_queries"
require "couchrest/model/extended_attachments"
require "couchrest/model/class_proxy"
require "couchrest/model/proxyable"
require "couchrest/model/associations"
require "couchrest/model/configuration"
require "couchrest/model/connection"
require "couchrest/model/designs"
require "couchrest/model/designs/design_doc"
require "couchrest/model/designs/view"

# Monkey patches applied to couchrest
require "couchrest/model/support/couchrest_database"

# Core Extensions
require "couchrest/model/core_extensions/hash"
require "couchrest/model/core_extensions/time_parsing"

# Base libraries
require "couchrest/model/embeddable"
require "couchrest/model/base"

# Add rails support *after* everything has loaded
if defined?(Rails)
  require "couchrest/railtie"
end
