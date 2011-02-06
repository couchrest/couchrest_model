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
require "couchrest/model/property"
require "couchrest/model/property_protection"
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
require "couchrest/model/associations"
require "couchrest/model/configuration"
require "couchrest/model/design"
require "couchrest/model/design/view"

# Monkey patches applied to couchrest
require "couchrest/model/support/couchrest"
require "couchrest/model/support/hash"

# Base libraries
require "couchrest/model/casted_model"
require "couchrest/model/base"

# Add rails support *after* everything has loaded

require "couchrest/railtie"
