
# Really simple money class for testing
class Money

  attr_accessor :cents, :currency

  def initialize(cents, currency = nil)
    self.cents = cents.to_i
    self.currency = currency
  end

  def to_s
    (self.cents.to_f / 100).to_s
  end

  def self.couchrest_typecast(parent, property, value)
    if parent.respond_to?(:currency)
      new(value, parent.currency)
    else
      new(value)
    end
  end

end
