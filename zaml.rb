require 'yaml'

class ZAML
    #
    # Class Methods
    #
    def self.dump(stuff, where)
        result = []
        z = new(result)
        stuff.to_zaml(z)
        z.nl
        where.print z.result
        end
    #
    # Object Methods
    #
    attr_accessor :result
    def initialize(result)
        @used = Hash.new(false)
        @result = result
        @already_done = {}
        @done_count = 0
        @indent = ''
        emit('---')
        end
    def nested(pre_emit=nil)
        emit(pre_emit) if pre_emit
        old_indent = @indent
        @indent += '  '
        yield
        @indent = old_indent
        end
    def first_time_only(stuff)
        this_stuff = stuff.object_id
        if @already_done.has_key?(this_stuff)
            @already_done[this_stuff][0..-1] = '&id%03d ' % (@done_count += 1) if @already_done[this_stuff].empty?
            emit(@already_done[this_stuff].gsub(/&/,'*'))
          else
            @already_done[this_stuff] = String.new
            emit(@already_done[this_stuff])
            yield
            end
        end
    def emit(s)
        @result << s
        @recent_nl = false
        end
    def nl(s='')
        unless @recent_nl 
            emit("\n")
            emit(@indent)
            end
        emit(s)
        @recent_nl = true
        end
    end

################################################################
#
#   Behavior for custom classes
#
################################################################

class Object
    def to_yaml_properties
        instance_variables.sort        # Default YAML behavior
        end
    def to_zaml(z)
        z.first_time_only(self) {
            z.nested("!ruby/object:#{self.class.name}") {
                instance_variables = to_yaml_properties
                if instance_variables.empty?
                    z.emit(" {}")
                  else
                    instance_variables.each { |v|
                        z.nl
                        v[1..-1].to_zaml(z)       # Remove leading '@'
                        z.emit(': ')
                        instance_variable_get(v).to_zaml(z)
                        }
                  end
                }
            }
        end
    end

################################################################
#
#   Behavior for built-in classes
#
################################################################

class NilClass
    def to_zaml(z)
        z.emit('')        # NOTE: blank turns into nil in YAML.load
        end
    end

class Symbol
    def to_zaml(z)
        z.emit(self.inspect)
        end
    end

class TrueClass
    def to_zaml(z)
        z.emit('true')
        end
    end

class FalseClass
    def to_zaml(z)
        z.emit('false')
        end
    end

class Numeric
    def to_zaml(z)
        z.emit(self.to_s)
        end
    end

class String
    ZAML_ESCAPES = %w{\x00 \x01 \x02 \x03 \x04 \x05 \x06 \a \x08 \t \n \v \f \r \x0e \x0f \x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17 \x18 \x19 \x1a \e \x1c \x1d \x1e \x1f }
    def to_zaml(z)
        z.first_time_only(self) { 
            if length < 80 and not self =~ /[\\"\x00-\x1f]/
                z.emit(self)
              else
                z.emit('"')
                z.emit(self.
                  gsub( /\\/, "\\\\\\" ).
                  gsub( /"/, "\\\"" ).
                  gsub( /([\x00-\x1f])/ ) { |x| ZAML_ESCAPES[ x.unpack("C")[0] ] }
                  )
                z.emit('"')
              end
            }
        end
    end

class Hash
    def to_zaml(z)
        z.first_time_only(self) { 
            z.nested {
                if empty?
                    z.emit('{}')
                  else
                    keys.each { |k|
                        z.nl
                        k.to_zaml(z)
                        z.emit(': ')
                        self[k].to_zaml(z)
                        }
                    end
                }
            }
        end
    end

class Array
    def to_zaml(z)
        z.first_time_only(self) {
            if empty?
                z.emit('[]')
              else
                each { |v|
                    z.nl('- ')
                    v.to_zaml(z)
                }
              end
            }
        end
    end

class Date
    def to_zaml(z)
        z.emit(sprintf("!timestamp %s", self.to_s))
        end
    end

class Range
    def to_zaml(z)
        z.first_time_only(self) {
            z.nested('!ruby/range') {
                z.nl
                z.emit('begin: ')
                z.emit(first)
                z.nl
                z.emit('end: ')
                z.emit(last)
                z.nl
                z.emit('excl: ')
                z.emit(exclude_end?)
                }
            }
        end
    end

################################################################
#
#   Unit testing
#
################################################################

if $0 == __FILE__
    #require 'test/unit'

    reps = ARGV[0] ? ARGV[0].to_i : 0
    class My_class
        def initialize
            @string = 'string...'
            @self = self
            @do_not_store_me = '*************** SHOULD NOT SHOW UP IN OUTPUT ***************'
            end
        def to_yaml_properties
            ['@string', '@self']
            end
        end

    require 'pp'

    my_range = 7..13
    my_obj = My_class.new
    my_dull_object = Object.new
    my_bob = 'bob'
    data = {:data => [1, my_range, my_obj, my_bob, my_dull_object, 2, 'test', "   funky\n test\n", true, false, {my_obj => 'obj is the key!'}, {:bob => 6.8, :sam => 9.7, :subhash => {:sh1 => 'one', :sh2 => 'two'}}, 6, my_bob, my_obj, my_range, 'bob', 1..10, 0...8]}

    puts '*************************** original ***************************'
    pp data

    puts '*************************** YAML ***************************'
    YAML.dump(data, STDOUT)

    puts '*************************** ZAML ***************************'
    ZAML.dump(data, STDOUT)

    # Data -> ZAML Dump -> YAML Load
    File.open('tmp-zaml','w') { |output| 
        ZAML.dump(data, output)
        }

    puts '*************************** loaded ***************************'
    File.open('tmp-zaml','r') { |input|
        pp YAML.load(input)
        }
    if reps > 0 
        big_data = []
        (1..reps).each { |i| 
            big_data << i
            big_data << My_class.new
            }
        start = Time.now
        File.open('tmp-zaml','w') { |output| 
            ZAML.dump(big_data, output)
            }
        print "#{reps} took #{Time.now-start}\n"
        end
    end
