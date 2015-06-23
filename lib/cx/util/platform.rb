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

  def osx?
    (platform =~ /x86_64-darwin14/) != nil
  end
end