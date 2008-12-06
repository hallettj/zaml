#
# ZAML -- A partial replacement for YAML, writen with speed and code clarity
#         in mind.  ZAML fixes one YAML bug (loading Exceptions) and provides 
#         a replacement for YAML.dump() unimaginatively called ZAML.dump(),
#         which is faster on all known cases and an order of magnitude faster 
#         with complex structures.
#
# http://github.com/hallettj/zaml/tree/master
#
# Authors: Markus Roberts, Jesse Hallet, Ian McIntosh, Igal Koshevoy
# 

require 'yaml'

class ZAML
    VERSION = 0.071
    
    class << self
      KEY_VALUE = /^([^ -].*?):\s*(.*?)\s*$/
      ARRAY_VALUE = /^\s*-\s*([^-].*?)\s*$/
      HASH_VALUE = /^\s+(.+?):\s*(.+?)\s*$/
      COMMENT = /^\s*(#.*?)?$/
      DOCUMENT = /^---\s*$/

      def load_file(path)
        load File.read(path)
      end

      def load(str)
        pairs = {}
        last = nil

        str.split(/\r?\n/).reverse_each do |line|
          case line
          when KEY_VALUE
            key = symbolize($1)
            if $2.empty?
              raise "format error for #{key}" unless last
              pairs[key] = last
              last = nil
            else
              raise "format error for #{key}" if last
              pairs[key] = objectify($2)
            end

          when ARRAY_VALUE
            # will cause error if last is {} (no method unshift)
            (last ||= []).unshift(objectify($1))
          when HASH_VALUE
            # will cause error if last is [] (str/sym as index)
            (last ||= {})[symbolize($1)] = objectify($2)
          when COMMENT then next
          when DOCUMENT then break
          else raise "unparseable line: #{line.inspect}"
          end
        end

        pairs.empty? ? (last == nil ? false : last) : pairs
      end
      
      def dump(stuff, where)
          result = []
          z = new(result)
          stuff.to_zaml(z)
          z.nl
          where.print(z.result,"\n")
          end

      def symbolize(str)
        str[0] == ?: ? str[1, str.length-1].to_sym : str
      end

      def objectify(str)
        case str
        when /^true$/i then true
        when /^false$/i then false
        when /^\d+(\.\d+)?$/ then $1 ? str.to_f : str.to_i
        else symbolize(str)
        end
      end
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
        emit('---')
        end
    def nested(pre_emit=nil)
        emit(pre_emit) if pre_emit
        old_indent = @indent
        @indent = (@indent && @indent+'  ') || ''
        yield
        @indent = old_indent
        end
    def first_time_only(stuff)
        #
        # YAML only wants objects in the datastream once; if the same object 
        #    occurs more than once, we need to emit a label ("&idxxx") on the 
        #    first occurrence and then emit a back reference (*idxxx") on any
        #    subsequent occurrence(s). 
        #
        # To accomplish this we keeps a hash (by object id) of the labels of
        #    the things we serialize as we begin to serialize them.  The label 
        #    is initially an empty string (since most objects are only going to
        #    be encountered once), but can be changed (Strings are muteable, 
        #    remember) to a valid label the first time it is subsequently used, 
        #    if it ever is.  Note that we need to do the label setup BEFORE we 
        #    start to serialize the object so that circular structures (in 
        #    which we will encounter a reference to the object as we serialize 
        #    it can be handled).
        #
        this_stuff = stuff.object_id
        if @already_done.has_key?(this_stuff)
            #
            # We have already serialized this object
            #
            if @already_done[this_stuff].empty?
                #
                # ...but this is the first time we have referred back to it,
                #     so we need to give it a unique label.  Note that the 
                #     string we are changing here has already been emitted, so
                #     this label will pop into existence at the appropriate 
                #     earlier point in the data stream.
                @already_done[this_stuff][0..-1] = '&id%03d ' % (@done_count += 1) 
                end
            # A back reference is just like the label, but with a '*' instead of a '*'
            emit(@already_done[this_stuff].gsub(/&/,'*'))
          else
            #
            # We haven't serialized this object yet
            #
            # We probably don't need a label on this object but we might, so we 
            #     emit a new, empty string as a placeholder.  If we don't need 
            #     a label this empty string has no effect, but if we do need 
            #     one we can modify the string to make the label show up in the 
            #     right place.
            emit(@already_done[this_stuff] = String.new,:placeholder)
            #
            # Then we just emit the object itself, prefixed with the (possibly,
            #     but not for certain permanently) null label string we just 
            #     made and emitted.
            yield
            end
        end
    def emit(s,placeholder=false)
        @result << s
        @recent_nl = false unless placeholder
        end
    def nl(s='')
        unless @recent_nl 
            emit("\n")
            emit(@indent) if @indent
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
    def zamlized_class_name(root)
        "!ruby/#{root.name.downcase}" + ((self.class == root) ? '' : ":#{self.class.name}")
        end
    def to_zaml(z)
        z.first_time_only(self) {
            z.nested(zamlized_class_name(Object)) {
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

class Regexp
    def to_zaml(z)
        z.emit("#{zamlized_class_name(Regexp)} #{inspect}")
        end
    end

class Exception
    def to_zaml(z)
        z.emit(zamlized_class_name(Exception))
        z.nested {
            z.nl("message: ")
            message.to_zaml(z)
            }
        end
    #
    # Monkey patch for buggy Exception restore in YAML
    #
    #     This makes it work for now but is not very future-proof; if things
    #     change we'll most likely want to remove this.  To mitigate the risks
    #     as much as possible, we test for the bug before appling the patch.
    #
    if yaml_new(self, :tag, "message" => "blurp").message != "blurp"
        def self.yaml_new( klass, tag, val )
            o = YAML.object_maker( klass, {} ).exception(val.delete( 'message'))
            val.each_pair do |k,v|
                o.instance_variable_set("@#{k}", v)
                end
            o
            end
        end
    end

class String
    ZAML_ESCAPES = %w{\x00 \x01 \x02 \x03 \x04 \x05 \x06 \a \x08 \t \n \v \f \r \x0e \x0f \x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17 \x18 \x19 \x1a \e \x1c \x1d \x1e \x1f }
    def escaped_for_zaml
        gsub( /\\/, "\\\\\\" ).
        gsub( /"/, "\\\"" ).
        gsub( /([\x00-\x1f])/ ) { |x| ZAML_ESCAPES[ x.unpack("C")[0] ] }
        end
    def to_zaml(z)
        z.first_time_only(self) { 
            if length > 80 
                z.emit('|')
                z.nested { each_line("\n") { |line| z.nl; z.emit(line.chomp) } }
                z.nl
              elsif (self =~ /^\w/) or (self[-1..-1] =~ /\w/) or (self =~ /[\\"\x00-\x1f]/)
                z.emit("\"#{escaped_for_zaml}\"")
              elsif 
                z.emit(self)
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
            z.nested {
                if empty?
                    z.emit('[]')
                  else
                    each { |v|
                        z.nl('- ')
                        v.to_zaml(z)
                        }
                  end
                } 
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
            z.nested(zamlized_class_name(Range)) {
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
