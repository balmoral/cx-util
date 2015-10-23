module CX
  class FilePath

    attr_reader :directory, :path

    def self.separator
      File::SEPARATOR
    end

    def initialize(*names)
      @path = @directory = nil
      if names
        if names.size == 1
          names = names.split('/')
        end
        first = names.first
        case first
          when '.', './'
            pwd = Dir.getwd.split('/')[1..-1]
            _names = pwd + names[1..-1]
            concat(*_names)
          else
            concat(*names)
        end
      end
    end

    def separator
      self.class.separator
    end

    def to_s
      @path
    end

    def to_a
      @array ||= to_s.split separator
    end

    # Returns a new FilePath with my path extended by given path
    def / (path)
      @path ? self.class.new(@path, path) : self.class.new(path)
    end

    def concat(*path)
      if path.size > 0
        @directory = nil
        @path ||= String.new
        path.each do |e|
          @path << (has_root_delimiter(e) ? '' : separator) << e.to_s
        end
      end
      self
    end

    def parent
      self.class.new(File.dirname(@path))
    end

    def exist?
      File.exist?(@path)
    end

    def size
      File.size(@path)
    end

    def size?
      File.size?(@path)
    end

    def assure_existence
      unless exist?
        parent.assure_existence
        Dir.mkdir(@path)
      end
      self
    end

    # Assumes receiver is path to file name.
    # Will ensure parent directories exist.
    def save(contents)
      p = parent
      printf("FilePath: assuring existence of %s\n", p.to_s)
      p.assure_existence
      printf("FilePath: writing %s\n", to_s)
      write { |f| f.write(contents) }
    end

    def read
      File.open(path) { |f| yield f }
    end

    def write(append: false)
      File.open(path, append ? 'a+' : 'w+') { |f| yield f }
    end

    def append
      File.open(path, 'a+') { |f| yield f }
    end

    def delete
      File.delete(path)
    end

    def add_root_delimiter
      (@path = String.new(self.class.separator) << @path) unless has_root_delimiter
      self
    end

    def add_end_delimiter
      (@path = @path << self.class.separator) unless has_end_delimiter
      self
    end

    def has_root_delimiter(arg = @path)
      path = arg.to_s
      path && path.size > 0 && path[0] == separator
    end

    def has_end_delimiter
      @path && @path.size > 0 && @path[@path.size-1] == separator
    end

    def directory
      @directory ||= (@path ? Dir.new(@path) : nil)
    end

    def directory_names
      directory ? Dir[directory.path + separator + '*'].select { |f| File.directory?(f) } : nil
    end

    def directory_basenames
      directory_names.collect{|e| File.basename(e)}
    end

    def file_names
      directory ? Dir[directory.path + separator + '*'].reject { |f| File.directory?(f) } : nil
    end

    def file_basenames
      file_names.collect{|e| File.basename(e)}
    end
  end
end

