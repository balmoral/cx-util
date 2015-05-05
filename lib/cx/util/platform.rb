class Object
  def platform
    RUBY_PLATFORM
  end

  def java?
    platform == 'java'
  end

  def opal?
    platform == 'opal'
  end
end