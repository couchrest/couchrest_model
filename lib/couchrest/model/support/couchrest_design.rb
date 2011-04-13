
CouchRest::Design.class_eval do

  # Calculate a checksum of the Design document. Used for ensuring the latest
  # version has been sent to the database.
  #
  # This will generate an flatterned, ordered array of all the elements of the
  # design document, convert to string then generate an MD5 Hash. This should
  # result in a consisitent Hash accross all platforms.
  #
  def checksum
    # create a copy of basic elements
    base = self.dup
    base.delete('_id')
    base.delete('_rev')
    result = nil
    flatten =
      lambda {|v|
        v.is_a?(Hash) ? v.flatten.map{|v| flatten.call(v)}.flatten : v.to_s
      }
    Digest::MD5.hexdigest(flatten.call(base).sort.join(''))
  end

end
