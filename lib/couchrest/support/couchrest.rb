
module CouchRest

  
  # The CouchRest module methods handle the basic JSON serialization 
  # and deserialization, as well as query parameters. The module also includes
  # some helpers for tasks like instantiating a new Database or Server instance.
  class << self

    # extracted from Extlib
    #
    # Constantize tries to find a declared constant with the name specified
    # in the string. It raises a NameError when the name is not in CamelCase
    # or is not initialized.
    #
    # @example
    # "Module".constantize #=> Module
    # "Class".constantize #=> Class
    def constantize(camel_cased_word)
      unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ camel_cased_word
        raise NameError, "#{camel_cased_word.inspect} is not a valid constant name!"
      end

      Object.module_eval("::#{$1}", __FILE__, __LINE__)
    end
    
    # extracted from Extlib
    #    
    # Capitalizes the first word and turns underscores into spaces and strips _id.
    # Like titleize, this is meant for creating pretty output.
    #
    # @example
    #   "employee_salary" #=> "Employee salary"
    #   "author_id" #=> "Author"
    def humanize(lower_case_and_underscored_word)
      lower_case_and_underscored_word.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
    end
    
  end

  class Database

    alias :delete_old! :delete!
    def delete!
      clear_extended_doc_fresh_cache
      delete_old!
    end

    # If the database is deleted, ensure that the design docs will be refreshed.
    def clear_extended_doc_fresh_cache
      ::CouchRest::ExtendedDocument.subclasses.each{|klass| klass.req_design_doc_refresh if klass.respond_to?(:req_design_doc_refresh)}
    end

  end

end
