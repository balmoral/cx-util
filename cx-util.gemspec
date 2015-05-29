Gem::Specification.new do |s|
  s.name        = 'cx-util'
  s.version     = '1.0.0'
  s.date        = '2015-04-26'
  s.summary     = 'CX utility classes'
  s.authors     = ['CG']
  s.email       = 'cojogu@gmail.com'
  s.files       = %w(
                    lib/cx/util/calc.rb
                    lib/cx/util/code_name.rb
                    lib/cx/util/debug.rb
                    lib/cx/util/file_path.rb
                    lib/cx/util/id.rb
                    lib/cx/util/key.rb
                    lib/cx/util/keyed.rb
                    lib/cx/util/line_fit.rb
                    lib/cx/util/math.rb
                    lib/cx/util/notifier.rb
                    lib/cx/util/observable.rb
                    lib/cx/util/platform.rb
                    lib/cx/util/random.rb
                    lib/cx/util/sort.rb
                    lib/cx/util/stack.rb
                    lib/cx/util/stats.rb
                    lib/cx/util/thread.rb
                    lib/cx/util/timer.rb
                    lib/cx/util/trace.rb
                    lib/cx/util/csv/constants.rb
                    lib/cx/util/csv/field.rb
                    lib/cx/util/csv/reader.rb
                    lib/cx/util/csv/row.rb
                    lib/cx/util/csv/table.rb
                  )
  s.homepage    = 'http://rubygems.org/gems/cx-util' # TODO: push to rubygems ??
  s.license     = 'MIT'

  s.add_dependency(%q<cx-core>)
end
