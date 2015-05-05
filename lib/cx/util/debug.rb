

class NilClass
  def to_human
    'nil'
  end
end

class Object
  def to_human
   to_s
  end

  def class?
    self.is_a? Class
  end

  def class_s
    class? ? name : self.class.name
  end

  # __method__ provides currently executing method
  # __callee__ provides caller of executing method
  # prepends class name and # or ## as appropriate
  def method_s(method_name, args = nil)
    method_s = arg_s = nil
    method_s = "#{class? ? '##' : '#'}#{method_name}" if method_name
    if args
      arg_s = '('
      if args.is_a? Hash
        c = 0
        args.each do |k,v|
          arg_s << ', ' unless c == 0
          arg_s << k.to_human
          arg_s << ': '
          arg_s << v.to_human
          c += 1
        end
      elsif args.is_a? Enumerable
        c = 0
        args.each do |v|
          arg_s << ', ' unless c == 0
          arg_s << v.to_human
          c += 1
        end
      else
        arg_s << args.to_human
      end
      arg_s << ')'
    end
    "#{class_s}#{method_s}#{arg_s}"
  end

  def trace_s(method, msg, args = nil)
    msg_s = " *{#{msg}}*"
    "#{Time.now.ymdhmsl}#{msg_s} #{method_s(method, args)}"
  end

  def cx_trace(method, msg, args = nil)
    msg_s = " *{#{msg}}*"
    puts_sync "#{Time.now.ymdhmsl} #{method_s(method, args)}\n=>#{msg_s}"
  end

  def cx_error(method, msg, args = nil)
    s = trace_s(method, msg, args)
    puts_sync "\n#{s}\n"
    fail s
  end

  def subclass_must_implement(method, args = nil)
    cx_error method, 'subclass must implement', args
  end

  def missing_case(missing_what, method, args = nil)
    cx_error method, "missing case: #{missing_what}", args
  end

  alias case_missing missing_case

  def missing_arg(missing_what, method)
    cx_error method, "missing argument: #{missing_what}"
  end

  alias arg_missing missing_arg

  def unfinished_code(method, what = nil)
    what_s = what ? " : #{what}" : nil
    cx_error method, "code unfinished#{what_s}"
  end

end