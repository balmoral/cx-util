# Simple model definition with
# a few convenience methods.
#
# Creates get/set methods for each attribute.
#
# #initialize will call #after_initialize

# TODO: extend so that hash of attributes, types
# default values, etc can be provided.
#
module CX
  class Model

    def self.attr(*attrs)
      # puts "#{self.class.name}##{__method__}(#{_name})"
      attrs.each do |_attr|
        attr = _attr.to_sym
        unless attrs.include?(attr)
          attrs << attr
          # reader
          define_method(attr) do
            stub_get(attr)
          end
          # writer
          define_method("#{attr}=".to_sym) do |value|
            stub_set(attr, value)
          end
        end
      end
    end

    def self.subclass(attr_names, parent: nil)
      sub = Class.new(parent || self)
      sub.attrs(attr_names)
      sub
    end

    # lazy initialize
    def self.attrs
      @attrs ||= [] + (superclass.respond_to?(:attrs) ? superclass.attrs : [])
    end

    def self.csv_head
      attrs.join(',')
    end

    def self.from_json(hash)
      result = new
      if hash
        attrs.each do |f|
          val = hash[f.to_s]
          result[f] = val
        end
      end
      result
    end

    def initialize(**args)
      @hash = {}
      if args && args.size > 0
        attrs.each do |f|
          @hash[f] = args[f]
        end
      end
      after_initialize
    end

    def after_initialize
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
      # attrs.each do |f|
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
      "#{self.class.name}: #{to_h}"
    end

    def attrs
      self.class.attrs
    end

    def csv_head
      self.class.csv_head
    end
  end

end

