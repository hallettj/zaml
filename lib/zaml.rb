#
# ZAML -- A partial replacement for YAML, writen with speed and code clarity
#         in mind.  ZAML fixes one YAML bug (loading Exceptions) and provides 
#         a replacement for YAML.dump() unimaginatively called ZAML.dump(),
#         which is faster on all known cases and an order of magnitude faster 
#         with complex structures.
#
# http://github.com/hallettj/zaml/tree/master
#
# Authors: Markus Roberts, Jesse Hallet, Ian McIntosh, Igal Koshevoy, Simon Chiang
# 

class ZAML
  VERSION = 0.071

  class << self
    def dump(obj, where="")
      z = new
      obj.to_zaml(z)
      z.nl
      where << z.to_s
    end
  end
  
  attr_reader :lines
  
  def initialize
    @lines = []
    @labels = {}
    @label_count = 0
    @indent = nil
    emit('--- ')
  end
  
  def nest(pre_emit=nil, indent='  ')
    emit(pre_emit) if pre_emit
    old_indent = @indent
    @indent = @indent ? "#{@indent}#{indent}" : ''
    yield
    @indent = old_indent
  end
  
  def label(obj, with_newline=false)
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
    id = obj.object_id
    if @labels.has_key?(id)
      #
      # We have already serialized this object
      #
      if @labels[id].empty?
        #
        # ...but this is the first time we have referred back to it,
        #     so we need to give it a unique label.  Note that the 
        #     string we are changing here has already been emitted, so
        #     this label will pop into existence at the appropriate 
        #     earlier point in the data stream.
        
        # ... some objects (ex the first member of an array or hash)
        # require a newline after the label
        @labels[id].replace('&id%03d%s' % [@label_count += 1, with_newline ? " \n#{@indent}" : ' '])
      end
      
      # A back reference is just like the label, but with a '*' instead 
      # of a '&' and minus the trailing space
      emit(@labels[id].gsub(/&/,'*').rstrip)
    else
      #
      # We haven't serialized this object yet
      #
      # We probably don't need a label on this object but we might, so we 
      #     emit a new, empty string as a placeholder.  If we don't need 
      #     a label this empty string has no effect, but if we do need 
      #     one we can modify the string to make the label show up in the 
      #     right place.
      emit(@labels[id] = String.new,:placeholder)
      #
      # Then we just emit the object itself, prefixed with the (possibly,
      #     but not for certain permanently) null label string we just 
      #     made and emitted.
      yield
    end
  end
  
  def emit(s,placeholder=false)
    @lines << s.to_s
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
  
  def to_s
    @lines.join
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
    "!ruby/#{root.name.downcase}#{self.class == root ? ' ' : ":#{self.class.name} "}"
  end
  
  def to_zaml(z)
    z.label(self) {
      z.nest(zamlized_class_name(Object)) {
        instance_variables = to_yaml_properties
        if instance_variables.empty?
          z.emit("{}\n")
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
  def to_zaml(z, as=nil)
    z.emit('')        # NOTE: blank turns into nil in YAML.load
  end
end

class Symbol
  def to_zaml(z, as=nil)
    z.emit(self.inspect)
  end
end

class TrueClass
  def to_zaml(z, as=nil)
    z.emit('true')
  end
end

class FalseClass
  def to_zaml(z, as=nil)
    z.emit('false')
  end
end

class Numeric
  def to_zaml(z, as=nil)
    z.emit(self.to_s)
  end
end

class Exception
  def to_zaml(z)
    z.emit(zamlized_class_name(Exception))
    z.nest {
      z.nl("message: ")
      message.to_zaml(z)
    }
  end
end

class Regexp
  def to_zaml(z, as=nil)
    z.emit("#{zamlized_class_name(Regexp)}#{inspect}")
  end
end

class String
  ZAML_ESCAPES = %w{\x00 \x01 \x02 \x03 \x04 \x05 \x06 \a \x08 \t \n \v \f \r \x0e \x0f \x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17 \x18 \x19 \x1a \e \x1c \x1d \x1e \x1f }
  
  def to_zaml(z, as=nil)
    case
    when self =~ /\n/
      z.emit('|-')
      z.nest { each_line("\n") { |line| z.nl; z.emit(line.chomp) } }
      z.nl
    when self =~ /^\s/ || self =~ /\s$/
      z.emit(%Q{"#{self =~ /[\\"]/ ? gsub( /\\/, "\\\\\\" ).gsub( /"/, "\\\"" ) : self}"})
    when self =~ /[\x00-\x1f]/
      z.emit("!binary |\n")
      z.emit([self].pack("m*"))
    else 
      z.emit(self)
    end
  end
end

# class Time
#   def to_zaml(z, as=nil)
#     # 2008-12-06 10:06:51.373758 -07:00
#     z.emit(self.strftime("%Y-%m-%d %H:%M:%s "))
#   end
# end
# 
# class Date
#   def to_zaml(z, as=nil)
#     z.emit(sprintf("!timestamp %s", self.to_s))
#   end
# end

class Range
  def to_zaml(z, as=nil)
    z.label(self) {
      z.nest(zamlized_class_name(Range)) {
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

class Hash
  def to_zaml(z, as=nil)
    z.label(self, true) { 
      z.nest {
        if empty?
          z.emit('{}')
        else
          each_pair { |k, v|
            z.nl
            k.to_zaml(z, :key)
            z.emit(': ')
            v.to_zaml(z, :value)
          }
        end
      }
    }
  end
end

class Array
  def to_zaml(z, as=nil)
    z.label(self, true) {
      z.nest(false, as == :value ? '' : '  ') {
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