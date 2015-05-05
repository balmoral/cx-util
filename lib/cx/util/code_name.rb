require 'cx/util/keyed'

# Expects using classes to implement
# a #code method, and an optional
# #name method. It implements the
# Keyed interface using code.

module CX
  module CodeName
    include CX::Keyed

    def name
      code.to_s
    end

    def key
      code
    end

    def to_s
      label
    end

    def label
      code.to_s
    end

    def code_name_label
      code.object_id == name.object_id ? code : "#{code} #{name}"
    end

  end
end


