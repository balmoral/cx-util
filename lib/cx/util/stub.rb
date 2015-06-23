# Example:
#
# class BarStub < Stub
#   field :symbol
#   field :date
#   field :open
#   field :high
#   field :low
#   field :close
#   field :volume
#   field :trends
# end
#
#

# A Stubbed class/object can proxy to
# embedded stub. For example
#
#   class Contact
#     extend  Stubbed
#     stub    ContactStub
#     ...
#     def initialize(stub)
#       @stub = stub
#     end
#   end
#
#   class ContactStub
#     field :name
#     field :address
#     field :phone
#     ...
#   end
#
# So now instances of Contact will behave
# just like ContactSub, but without using
# class inheritance, allowing say Contact
# to inherit from another class instead,
# such as Volt::Model...
#
# Because we are cognisant of classes such
# as Volt::Model relying on the dreaded
# #method_missing to implement a lot of
# stuff, we are avoiding use of it
# (for now...)
#

module StubWrap
  def initialize(stub = nil)
    @stub = stub
  end
  def stub
    @stub
  end
  def stub=(stub)
    @stub = stub
  end
end

module Stubbed
  def from_json(hash)
    puts "#{name}.from_json(#{hash})"
    new @stub_class.from_json(hash)
  end

  def stub(stub_class)
    unless stub_class < Stub
      raise "Stubbed.stub(#{stub_class.name}) : stub class must inherit from Stub"
    end
    if @stub_class
      raise "Stubbed.stub(#{stub_class.name}) : already stubbed to #{@stub_class.name}"
    end
    @stub_class = stub_class
    current_methods = methods
    @stub_class.methods.each do |method|
      # NB don't override 'naturally occurring' or otherwise pre-defined class methods
      if current_methods.include?(method)
        # puts "not overriding #{name}###{method}"
      else
        # puts "adding #{name}###{method}"
        define_singleton_method(method) do |*args, &block|
          stub_class.send(method, *args, &block)
        end
      end
    end
    include(StubWrap)
    current_methods = public_instance_methods
    @stub_class.public_instance_methods.each do |method|
      # NB don't override 'naturally occurring' or otherwise pre-defined instance methods
      if current_methods.include?(method)
        # puts "not overriding #{name}##{method}"
      else
        # puts "adding #{name}##{method}"
        define_method(method) do |*args, &block|
          stub.send(method, *args, &block)
        end
      end
    end
  end
end

class Stub
  # When class is defined such as
  #   class MyStub
  #     field: name
  #     ...
  #   end
  #
  # opts not used for now...
  def self.field(_field_name, opts = {})
    # puts "#{self.class.name}##{__method__}(#{_name})"
    field_name = _field_name.to_sym
    unless fields.include?(field_name)
      fields << field_name
      define_method(field_name) {stub_get field_name}
      define_method("#{field_name}=".to_sym) {|value| stub_set field_name, value}
    end
  end

  def self.fields
    @fields ||= [] + (self < Stub ? superclass.fields : [])
  end

  def self.csv_head
    fields.join(',')
  end

  def self.from_json(hash)
    result = new
    if hash
      fields.each do |f|
        val = hash[f.to_s]
        result[f] = val
      end
    end
    result
  end

  def initialize(**args)
    @hash = {}
    if args && args.size > 0
      fields.each do |f|
        @hash[f] = args[f]
      end
    end
  end

  def [](attr)
    @hash[attr.to_sym]
  end


  def []=(attr, val)
    @hash[attr.to_sym] = val
  end

  alias_method :stub_get, :[]
  alias_method :stub_set, :[]=

  def to_csv
    csv = ''
    fields.each do |f|
      csv = csv + ',' unless csv.size == 0
      v = @hash[f]
      csv = csv + v if v
    end
    csv
  end

  def to_h
    @hash #.dup
  end

  def to_s
    "#{self.class.name} #{to_h}"
  end

  def fields
    self.class.fields
  end

  def csv_head
    self.class.csv_head
  end
end


# class TestStub < Stub
#   field :code
# end

# class Test
#   extend Stubbed
#   stub TestStub
# end