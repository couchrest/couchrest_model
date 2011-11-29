
CouchRest::Design.class_eval do

  # Calculate and update the checksum of the Design document.
  # Used for ensuring the latest version has been sent to the database.
  #
  # This will generate an flatterned, ordered array of all the elements of the
  # design document, convert to string then generate an MD5 Hash. This should
  # result in a consisitent Hash accross all platforms.
  #
  def checksum!
    # create a copy of basic elements
    base = self.dup
    base.delete('_id')
    base.delete('_rev')
    base.delete('couchrest-hash')
    result = nil
    flatten =
      lambda {|r|
        (recurse = lambda {|v|
          if v.is_a?(Hash) || v.is_a?(CouchRest::Document)
            v.to_a.map{|v| recurse.call(v)}.flatten
          elsif v.is_a?(Array)
            v.flatten.map{|v| recurse.call(v)}
          else
            v.to_s
          end
        }).call(r)
      }
    self['couchrest-hash'] = Digest::MD5.hexdigest(flatten.call(base).sort.join(''))
  end

end
