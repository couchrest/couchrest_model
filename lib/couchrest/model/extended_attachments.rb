module CouchRest
  module Model
    module ExtendedAttachments
      extend ActiveSupport::Concern

      # Add a file attachment to the current document. Expects
      # :file and :name to be included in the arguments.
      def create_attachment(args={})
        raise ArgumentError unless args[:file] && args[:name]
        return if has_attachment?(args[:name])
        set_attachment_attr(args)
      rescue ArgumentError
        raise ArgumentError, 'You must specify :file and :name'
      end
      
      # return all attachments
      def attachments
        self['_attachments'] ||= {}
      end

      # reads the data from an attachment
      def read_attachment(attachment_name)
        database.fetch_attachment(self, attachment_name)
      end

      # modifies a file attachment on the current doc
      def update_attachment(args={})
        raise ArgumentError unless args[:file] && args[:name]
        return unless has_attachment?(args[:name])
        delete_attachment(args[:name])
        set_attachment_attr(args)
      rescue ArgumentError
        raise ArgumentError, 'You must specify :file and :name'
      end

      # deletes a file attachment from the current doc
      def delete_attachment(attachment_name)
        return unless attachments
        if attachments.include?(attachment_name)
          attachments.delete attachment_name
        end
      end

      # returns true if attachment_name exists
      def has_attachment?(attachment_name)
        !!(attachments && attachments[attachment_name] && !attachments[attachment_name].empty?)
      end

      # returns URL to fetch the attachment from
      def attachment_url(attachment_name)
        return unless has_attachment?(attachment_name)
        "#{database.root}/#{self.id}/#{attachment_name}"
      end
      
      # returns URI to fetch the attachment from
      def attachment_uri(attachment_name)
        return unless has_attachment?(attachment_name)
        "#{database.uri}/#{self.id}/#{attachment_name}"
      end
      
      private
      
        def get_mime_type(path)
          return nil if path.nil?
          type = ::MIME::Types.type_for(path)
          type.empty? ? nil : type.first.content_type
        end

        def set_attachment_attr(args)
          content_type = args[:content_type] ? args[:content_type] : get_mime_type(args[:file].path)
          content_type ||= (get_mime_type(args[:name]) || 'text/plain')

          attachments[args[:name]] = {
            'content_type' => content_type,
            'data'         => args[:file].read
          }
        end
      
    end # module ExtendedAttachments
  end
end
