

module CX
  class Stub
    # When class is defined such as
    #   class MyStub < Stub
    #     field: name
    #     ...
    #   end
    #
    # TODO: opts not used for now...
    def self.field(_field_name, **_opts)
      # puts "#{self.class.name}##{__method__}(#{_name})"
      field_name = _field_name.to_sym
      unless fields.include?(field_name)
        fields << field_name
        define_method(field_name) { stub_get(field_name) }
        define_method("#{field_name}=".to_sym) {|value| stub_set(field_name, value) }
      end
    end

    def self.set_fields(field_names)
      field_names.each do |name|
        field(name)
      end
    end

    def self.sub_with_fields(field_names, parent: nil)
      sub = Class.new(parent || self)
      sub.set_fields(field_names)
      sub
    end

    def self.fields
      # done this way to help Opal which gets < method wrong
      @fields ||= [] + (superclass.respond_to?(:fields) ? superclass.fields : [])
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
      @hash.values.join(',')
      # csv = ''
      # fields.each do |f|
      #   csv = csv + ',' unless csv.size == 0
      #   v = @hash[f]
      #   csv = csv + v.to_s if v
      # end
      # csv
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

  # A Stubbed class/object can proxy to
  # an embedded stub. For example
  #
  #   class Contact
  #     field :name
  #     field :address
  #     field :phone
  #     ...
  #   end
  #
  #   class Employee
  #     extend  Stubbed
  #     embed   Contact
  #   end
  #
  #   stub = ContactStub.new
  #   contact = Contact.new(stub)
  #
  # So now instances of Employee will behave
  # just like Contact, but without using
  # class inheritance, allowing Employee
  # to inherit from another class instead,
  # such as Volt::Model...
  #
  # Because we are cognisant of classes such
  # as Volt::Model relying on the dreaded
  # #method_missing to implement a lot of
  # stuff, we are avoiding use of it
  # (for now...)
  #
  # TODO: needs a lot more thought and work
  # TODO: allow multiple embeds like multiple inheritance
  #
  module EmbeddedStub
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

    def embed(stub_class)
      unless stub_class < Stub
        raise "Stubbed.stub(#{stub_class.name}) : stub class must inherit from Stub"
      end
      if @stub_class
        raise "Stubbed.stub(#{stub_class.name}) : already stubbed to #{@stub_class.name}"
      end
      @stub_class = stub_class
      # add class methods from stub to stubbed
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
      # include the StubEmbed module in the Stubbed class
      include(EmbeddedStub)
      # add instance methods from stub to stubbed
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

end


# class TestStub < CX::Stub
#   field :code
# end

# class Test
#   extend CX::Stubbed
#   stub TestStub
# end