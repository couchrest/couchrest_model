module CouchRest
  module Model
    module Translation
      include ActiveModel::Translation

      def lookup_ancestors #:nodoc:
        klass = self
        classes = [klass]
        return classes if klass == CouchRest::Model::Base

        while klass.superclass != CouchRest::Model::Base
          classes << klass = klass.superclass
        end
        classes
      end

      def i18n_scope
        :couchrest
      end
    end
  end
end
