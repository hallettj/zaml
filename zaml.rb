require 'yaml'
require 'set'

class ZAML
	BASIC_TYPES = Set.new([String, Symbol, Float, Numeric, Integer, Fixnum, TrueClass, FalseClass, Array, Hash, Range, NilClass])

	#
	# Class Methods
	#
	def self.dump(stuff, where)
		z = new(where)
		z.pass = 1
		z.dump(stuff)
		z.pass = 2
		#z.nested(-2) {		NOTE: this solves the problem that the top level is improperly nested, but it's an ugly hack, and YAML seems to load the indented file fine anyway...
		z.dump(stuff)
		#}
		z.nl
	end

	#
	# Object Methods
	#
	def initialize(where)
		@used = Hash.new(false)
		@dest = where
		emit('---')
	end

	def pass=(n)
		@already_done = {}
		@done_count = 0
		@indent = 0
		@pass = n
	end

	def nested(n=2)
		@indent += n
		yield
		@indent -= n
	end

	def nl(s='')
		if @pass == 2
			@dest.print("\n", ' '*@indent) unless @recent_nl
			@dest.print(s)
			@recent_nl = true
		end
	end

	def dump(stuff)
		if @pass == 1
			if @already_done.has_key?(stuff)
				# This object is referred to elsewhere
				@used[stuff] = true
			else
				@already_done[stuff] = (@done_count += 1)
				stuff.to_zaml(self)
			end
		else
			if @already_done.has_key?(stuff)
				emit(sprintf('*id%03d', @already_done[stuff]))
			else
				unless BASIC_TYPES.include?(stuff.class)
					@already_done[stuff] = (@done_count += 1)
					emit(sprintf('&id%03d ', @already_done[stuff])) if @used[stuff]
				end
				stuff.to_zaml(self)
			end
		end
	end

	def emit(s)
		@dest.print(s) unless @pass == 1
		@recent_nl = false
	end
end

################################################################
#
#   Behavior for custom classes
#
################################################################

class Object
	def to_yaml_properties
		instance_variables.sort		# Default YAML behavior
	end

	def to_zaml(z)
		z.emit("!ruby/object:#{self.class.name}")
		z.nested {
			instance_variables = to_yaml_properties
			if instance_variables.empty?
				z.emit(" {}\n")		# NOTE: the \n here doesn't seem to be necessary but YAML does it...
			else
				instance_variables.each { |v|
					z.nl
					z.dump(v[1..-1])		# Remove leading '@'
					z.emit(': ')
					z.dump(self.instance_variable_get(v))
				}
			end
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
		z.emit('')		# NOTE: blank turns into nil in YAML.load
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
	def to_zaml(z)
		z.emit(self)		# TODO: support "    leading/trailing space  " and encode special characters (YAML does "⚙" => "\xE2\x9A\x99")
	end
end

class Hash
	def to_zaml(z)
		z.nested {
			if empty?
				z.emit('{}')
			else
				keys.each { |k|
					z.nl
					z.dump(k)
					z.emit(': ')
					z.dump(self[k])
				}
			end
		}
	end
end

class Array
	def to_zaml(z)
		if empty?
			z.emit('[]')
		else
			each { |v|
				z.nl('- ')
				z.dump(v)
			}
		end
	end
end

class Date
	def to_zaml(z)
		z.emit(sprintf("!timestamp %s", self.to_s))
	end
end

class Range
	def to_zaml(z)
		z.emit('!ruby/range')
		z.nested {
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
	end
end

################################################################
#
#   Unit testing
#
################################################################

if $0 == __FILE__
	#require 'test/unit'

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

	my_obj = My_class.new
	data = {:data => [1, my_obj, 2, 'test', true, false, {my_obj => 'obj is the key!'}, {:bob => 6.8, :sam => 9.7, :subhash => {:sh1 => 'one', :sh2 => 'two'}}, 6, my_obj, 1..10, 0...8]}

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
end
