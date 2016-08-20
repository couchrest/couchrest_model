# encoding: utf-8
require 'spec_helper'

describe "Type Casting" do

  before(:each) do
    @course = Course.new(:title => 'Relaxation')
  end

  describe "when value is nil" do
    it "leaves the value unchanged" do
      @course.title = nil
      expect(@course['title']).to eq(nil)
    end
  end

  describe "when value is empty string" do
    it "leaves the value unchanged" do
      @course.title = ""
      expect(@course['title']).to eq("")
    end
  end

  describe "when blank is not allow on property" do
    it "leaves nil as nil" do
      @course.subtitle = nil
      expect(@course['subtitle']).to eq(nil)
    end
    it "converts blank to nil" do
      @course.subtitle = ""
      expect(@course['subtitle']).to eq(nil)
    end
    it "leaves text as text" do
      @course.subtitle = "Test"
      expect(@course['subtitle']).to eq("Test")
    end
  end

  describe "when type primitive is an Object" do
    it "it should not cast given value" do
      @course.participants = [{}, 'q', 1]
      expect(@course['participants']).to eq([{}, 'q', 1])
    end

    it "should cast started_on to Date" do
      @course.started_on = Date.today
      expect(@course['started_on']).to be_an_instance_of(Date)
    end
  end

  describe "when class responds to .couchrest_typecast" do
    it "should accept call" do
      @course.price = "1299"
      expect(@course.price.cents).to eql(1299)
      expect(@course.price.currency).to eql('EUR')
    end
  end

  describe "when type primitive is a String" do
    it "keeps string value unchanged" do
      value = "1.0"
      @course.title = value
      expect(@course['title']).to equal(value)
    end

    it "it casts to string representation of the value" do
      @course.title = 1.0
      expect(@course['title']).to eql("1.0")
    end
  end

  describe "when type primitive is a Symbol" do
    it "keeps symbol value unchanged" do
      value = :a_symbol
      @course.symbol = value
      expect(@course['symbol']).to equal(:a_symbol)
    end

    it "it casts to symbol representation of the value" do
      @course.symbol = "a_symbol"
      expect(@course['symbol']).to equal(:a_symbol)
    end

    it "turns blank value into nil" do
      @course.symbol = ""
      expect(@course['symbol']).to be_nil
    end
  end


  describe 'when type primitive is a Float' do
    it 'returns same value if a float' do
      value = 24.0
      @course.estimate = value
      expect(@course['estimate']).to equal(value)
    end

    it 'returns float representation of a zero string integer' do
      @course.estimate = '0'
      expect(@course['estimate']).to eql(0.0)
    end

    it 'returns float representation of a positive string integer' do
      @course.estimate = '24'
      expect(@course['estimate']).to eql(24.0)
    end

    it 'returns float representation of a negative string integer' do
      @course.estimate = '-24'
      expect(@course['estimate']).to eql(-24.0)
    end

    it 'returns float representation of a zero string float' do
      @course.estimate = '0.0'
      expect(@course['estimate']).to eql(0.0)
    end

    it 'returns float representation of a positive string float' do
      @course.estimate = '24.35'
      expect(@course['estimate']).to eql(24.35)
    end

    it 'returns float representation of a negative string float' do
      @course.estimate = '-24.35'
      expect(@course['estimate']).to eql(-24.35)
    end

    it 'returns float representation of a zero string float, with no leading digits' do
      @course.estimate = '.0'
      expect(@course['estimate']).to eql(0.0)
    end

    it 'returns float representation of a positive string float, with no leading digits' do
      @course.estimate = '.41'
      expect(@course['estimate']).to eql(0.41)
    end

    it 'returns float representation of a zero integer' do
      @course.estimate = 0
      expect(@course['estimate']).to eql(0.0)
    end

    it 'returns float representation of a positive integer' do
      @course.estimate = 24
      expect(@course['estimate']).to eql(24.0)
    end

    it 'returns float representation of a negative integer' do
      @course.estimate = -24
      expect(@course['estimate']).to eql(-24.0)
    end

    it 'returns float representation of a zero decimal' do
      @course.estimate = BigDecimal('0.0')
      expect(@course['estimate']).to eql(0.0)
    end

    it 'returns float representation of a positive decimal' do
      @course.estimate = BigDecimal('24.35')
      expect(@course['estimate']).to eql(24.35)
    end

    it 'returns float representation of a negative decimal' do
      @course.estimate = BigDecimal('-24.35')
      expect(@course['estimate']).to eql(-24.35)
    end

    it 'return float of a number with commas instead of points for decimals' do
      @course.estimate = '23,35'
      expect(@course['estimate']).to eql(23.35)
    end

    it "should handle numbers with commas and points" do
      @course.estimate = '1,234.00'
      expect(@course.estimate).to eql(1234.00)
    end

    it "should handle a mis-match of commas and points and maintain the last one" do
      @course.estimate = "1,232.434.123,323"
      expect(@course.estimate).to eql(1232434123.323)
    end

    it "should handle numbers with whitespace" do
      @course.estimate = " 24.35 "
      expect(@course.estimate).to eql(24.35)
    end

    it "should handle numbers with unit strings" do
      @course.estimate = "23.21 points"
      expect(@course['estimate']).to eql(23.21)
    end

    [ '', 'string', ' foo ' ].each do |value|
      it "should typecast string without a number to nil (#{value.inspect})" do
        @course.estimate = value
        expect(@course['estimate']).to be_nil
      end
    end

    [ '00.0', '0.', '-.0' ].each do |value|
      it "should typecast strings with strange numbers to zero (#{value.inspect})" do
        @course.estimate = value
        expect(@course['estimate']).to eql(0.0)
      end
    end

    [ Object.new, true ].each do |value|
      it "should not typecast non-numeric value that won't respond to #to_f (#{value.inspect})" do
        @course.estimate = value
        expect(@course['estimate']).to equal(nil)
      end
    end

  end

  describe 'when type primitive is a Integer' do
    it 'returns same value if an integer' do
      value = 24
      @course.hours = value
      expect(@course['hours']).to equal(value)
    end

    it 'returns integer representation of a zero string integer' do
      @course.hours = '0'
      expect(@course['hours']).to eql(0)
    end

    it 'returns integer representation of a positive string integer' do
      @course.hours = '24'
      expect(@course['hours']).to eql(24)
    end

    it 'returns integer representation of a negative string integer' do
      @course.hours = '-24'
      expect(@course['hours']).to eql(-24)
    end

    it 'returns integer representation of a zero string float' do
      @course.hours = '0.0'
      expect(@course['hours']).to eql(0)
    end

    it 'returns integer representation of a positive string float' do
      @course.hours = '24.35'
      expect(@course['hours']).to eql(24)
    end

    it 'returns integer representation of a negative string float' do
      @course.hours = '-24.35'
      expect(@course['hours']).to eql(-24)
    end

    it 'returns integer representation of a zero string float, with no leading digits' do
      @course.hours = '.0'
      expect(@course['hours']).to eql(0)
    end

    it 'returns integer representation of a positive string float, with no leading digits' do
      @course.hours = '.41'
      expect(@course['hours']).to eql(0)
    end

    it 'returns integer representation of a zero float' do
      @course.hours = 0.0
      expect(@course['hours']).to eql(0)
    end

    it 'returns integer representation of a positive float' do
      @course.hours = 24.35
      expect(@course['hours']).to eql(24)
    end

    it 'returns integer representation of a negative float' do
      @course.hours = -24.35
      expect(@course['hours']).to eql(-24)
    end

    it 'returns integer representation of a zero decimal' do
      @course.hours = '0.0'
      expect(@course['hours']).to eql(0)
    end

    it 'returns integer representation of a positive decimal' do
      @course.hours = '24.35'
      expect(@course['hours']).to eql(24)
    end

    it 'returns integer representation of a negative decimal' do
      @course.hours = '-24.35'
      expect(@course['hours']).to eql(-24)
    end

    it "should handle numbers with whitespace" do
      @course.hours = " 24 "
      expect(@course['hours']).to eql(24)
    end

    it "should handle numbers with string units" do
      @course.hours = "23 hours"
      expect(@course['hours']).to eql(23)
    end

    it "should typecast an empty string to nil" do
      @course.hours = ""
      expect(@course['hours']).to be_nil
    end

    [ '', 'string', ' foo ' ].each do |value|
      it "should typecast string without a number to nil (#{value.inspect})" do
        @course.hours = value
        expect(@course['hours']).to be_nil
      end
    end

    [ '00.0', '0.', '-.0' ].each do |value|
      it "should typecast strings with strange numbers to zero (#{value.inspect})" do
        @course.hours = value
        expect(@course['hours']).to eql(0)
      end
    end

    [ Object.new, true ].each do |value|
      it "should not typecast non-numeric value that won't respond to #to_i (#{value.inspect})" do
        @course.hours = value
        expect(@course['hours']).to equal(nil)
      end
    end

  end

  describe 'when type primitive is a BigDecimal' do
    it 'returns same value if a decimal' do
      value = BigDecimal('24.0')
      @course.profit = value
      expect(@course['profit']).to equal(value)
    end

    it 'returns decimal representation of a zero string integer' do
      @course.profit = '0'
      expect(@course['profit']).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive string integer' do
      @course.profit = '24'
      expect(@course['profit']).to eql(BigDecimal('24.0'))
    end

    it 'returns decimal representation of a negative string integer' do
      @course.profit = '-24'
      expect(@course['profit']).to eql(BigDecimal('-24.0'))
    end

    it 'returns decimal representation of a zero string float' do
      @course.profit = '0.0'
      expect(@course['profit']).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive string float' do
      @course.profit = '24.35'
      expect(@course['profit']).to eql(BigDecimal('24.35'))
    end

    it 'returns decimal representation of a negative string float' do
      @course.profit = '-24.35'
      expect(@course['profit']).to eql(BigDecimal('-24.35'))
    end

    it 'returns decimal representation of a zero string float, with no leading digits' do
      @course.profit = '.0'
      expect(@course['profit']).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive string float, with no leading digits' do
      @course.profit = '.41'
      expect(@course['profit']).to eql(BigDecimal('0.41'))
    end

    it 'returns decimal representation of a zero integer' do
      @course.profit = 0
      expect(@course['profit']).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive integer' do
      @course.profit = 24
      expect(@course['profit']).to eql(BigDecimal('24.0'))
    end

    it 'returns decimal representation of a negative integer' do
      @course.profit = -24
      expect(@course['profit']).to eql(BigDecimal('-24.0'))
    end

    it 'returns decimal representation of a zero float' do
      @course.profit = 0.0
      expect(@course['profit']).to eql(BigDecimal('0.0'))
    end

    it 'returns decimal representation of a positive float' do
      @course.profit = 24.35
      expect(@course['profit']).to eql(BigDecimal('24.35'))
    end

    it 'returns decimal representation of a negative float' do
      @course.profit = -24.35
      expect(@course['profit']).to eql(BigDecimal('-24.35'))
    end

    it "should handle numbers with whitespace" do
      @course.profit = " 24.35 "
      expect(@course['profit']).to eql(BigDecimal('24.35'))
    end

    it "should handle numbers with strings" do
      @course.profit = "22.23 euros"
      expect(@course['profit']).to eql(BigDecimal('22.23'))
    end

    it "should typecast an empty string to nil" do
      @course.profit = ""
      expect(@course['profit']).to be_nil
    end

    [ '', 'string', ' foo ' ].each do |value|
      it "should typecast string without a number to nil (#{value.inspect})" do
        @course.profit = value
        expect(@course['profit']).to be_nil
      end
    end

    [ '00.0', '0.', '-.0' ].each do |value|
      it "should typecast strings with strange numbers to zero (#{value.inspect})" do
        @course.profit = value
        expect(@course['profit']).to eql(0.0)
      end
    end

    [ Object.new, true ].each do |value|
      it "should typecast non-numeric value that won't respond to to_d (#{value.inspect}) as nil" do
        @course.profit = value
        expect(@course['profit']).to equal(nil)
      end
    end

  end

  describe 'when type primitive is a DateTime' do
    describe 'and value given as a hash with keys like :year, :month, etc' do
      it 'builds a DateTime instance from hash values' do
        @course.updated_at = {
          :year  => '2006',
          :month => '11',
          :day   => '23',
          :hour  => '12',
          :min   => '0',
          :sec   => '0'
        }
        result = @course['updated_at']

        expect(result).to be_kind_of(DateTime)
        expect(result.year).to eql(2006)
        expect(result.month).to eql(11)
        expect(result.day).to eql(23)
        expect(result.hour).to eql(12)
        expect(result.min).to eql(0)
        expect(result.sec).to eql(0)
      end
    end

    describe 'and value is a string' do
      it 'parses the string' do
        @course.updated_at = 'Dec, 2006'
        expect(@course['updated_at'].month).to eq(12)
      end
    end

    it 'does not typecast non-datetime values' do
      @course.updated_at = 'not-datetime'
      expect(@course['updated_at']).to be_nil
    end
  end

  describe 'when type primitive is a Date' do
    describe 'and value given as a hash with keys like :year, :month, etc' do
      it 'builds a Date instance from hash values' do
        @course.started_on = {
          :year  => '2007',
          :month => '3',
          :day   => '25'
        }
        result = @course['started_on']

        expect(result).to be_kind_of(Date)
        expect(result.year).to eql(2007)
        expect(result.month).to eql(3)
        expect(result.day).to eql(25)
      end
    end

    describe 'and value is a string' do
      it 'parses the string' do
        @course.started_on = 'Dec 20th, 2006'
        expect(@course.started_on.month).to eq(12)
        expect(@course.started_on.day).to eq(20)
        expect(@course.started_on.year).to eq(2006)
      end
    end

    it 'does not typecast non-date values' do
      @course.started_on = 'not-date'
      expect(@course['started_on']).to be_nil
    end
  end

  describe 'when type primitive is a Time' do
    describe 'and value given as a hash with keys like :year, :month, etc' do
      it 'builds a Time instance from hash values' do
        @course.ends_at = {
          :year  => '2006',
          :month => '11',
          :day   => '23',
          :hour  => '12',
          :min   => '0',
          :sec   => '0'
        }
        result = @course['ends_at']

        expect(result).to be_kind_of(Time)
        expect(result.year).to  eql(2006)
        expect(result.month).to eql(11)
        expect(result.day).to   eql(23)
        expect(result.hour).to  eql(12)
        expect(result.min).to   eql(0)
        expect(result.sec).to   eql(0)
      end
    end

    describe 'and value is a string' do
      it 'parses the string' do
        t = Time.new(2011, 4, 1, 18, 50, 32, "+02:00")
        @course.ends_at = t.strftime('%Y/%m/%d %H:%M:%S %z')
        expect(@course['ends_at'].year).to  eql(t.year)
        expect(@course['ends_at'].month).to eql(t.month)
        expect(@course['ends_at'].day).to   eql(t.day)
        expect(@course['ends_at'].hour).to  eql(t.hour)
        expect(@course['ends_at'].min).to   eql(t.min)
        expect(@course['ends_at'].sec).to   eql(t.sec)
      end
      it 'parses the string without offset as UTC' do
        t = Time.now.utc
        @course.ends_at = t.strftime("%Y-%m-%d %H:%M:%S")
        expect(@course.ends_at.utc?).to be_truthy
        expect(@course['ends_at'].year).to  eql(t.year)
        expect(@course['ends_at'].month).to eql(t.month)
        expect(@course['ends_at'].day).to   eql(t.day)
        expect(@course['ends_at'].hour).to  eql(t.hour)
        expect(@course['ends_at'].min).to   eql(t.min)
        expect(@course['ends_at'].sec).to   eql(t.sec)
      end
    end

    it "converts a time value into utc" do
      t = Time.new(2011, 4, 1, 18, 50, 32, "+02:00")
      @course.ends_at = t
      expect(@course.ends_at.utc?).to be_truthy
      expect(@course.ends_at.to_i).to eql(Time.utc(2011, 4, 1, 16, 50, 32).to_i)
    end

    it 'does not typecast non-time values' do
      @course.ends_at = 'not-time'
      expect(@course['ends_at']).to be_nil
    end
  end

  describe 'when type primitive is a Class' do
    it 'returns same value if a class' do
      value = Course
      @course.klass = value
      expect(@course['klass']).to equal(value)
    end

    it 'returns the class if found' do
      @course.klass = 'Course'
      expect(@course['klass']).to eql(Course)
    end

    it 'does not typecast non-class values' do
      @course.klass = 'NoClass'
      expect(@course['klass']).to be_nil
    end
  end

  describe 'when type primitive is a Boolean' do

    [ true, 'true', 'TRUE', '1', 1, 't', 'T' ].each do |value|
      it "returns true when value is #{value.inspect}" do
        @course.active = value
        expect(@course['active']).to be_truthy
      end
    end

    [ false, 'false', 'FALSE', '0', 0, 'f', 'F' ].each do |value|
      it "returns false when value is #{value.inspect}" do
        @course.active = value
        expect(@course['active']).to be_falsey
      end
    end

    [ 'string', 2, 1.0, BigDecimal('1.0'), DateTime.now, Time.now, Date.today, Class, Object.new, ].each do |value|
      it "does not typecast value #{value.inspect}" do
        @course.active = value
        expect(@course['active']).to be_nil
      end
    end

    it "should respond to requests with ? modifier" do
      @course.active = nil
      expect(@course.active?).to be_falsey
      @course.active = false
      expect(@course.active?).to be_falsey
      @course.active = true
      expect(@course.active?).to be_truthy
    end

    it "should respond to requests with ? modifier on TrueClass" do
      @course.very_active = nil
      expect(@course.very_active?).to be_falsey
      @course.very_active = false
      expect(@course.very_active?).to be_falsey
      @course.very_active = true
      expect(@course.very_active?).to be_truthy
    end
  end

end


