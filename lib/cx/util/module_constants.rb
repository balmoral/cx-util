module CX
  module ModuleConstants

    # Return a hash of constant value => name.
    # Fails if any duplicate value.
    def constants_by_value
      unless @constants_by_value
        @constants_by_value = {}
        constants.each do |name|
          val = const_get(name)
          if (existing = @constants_by_value[val])
            fail "value #{val} is duplicated for #{existing} and #{name}"
          end
          @constants_by_value[val] = name
        end
      end
      @constants_by_value
    end

    def constant_name(constant_value)
      constants_by_value[constant_value]
    end

  end
end