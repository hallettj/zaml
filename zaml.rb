
class Zamlizer
    def self.dump(stuff,where)
        z = new(where)
        z.pass = 1
        z.dump(stuff)
        z.pass = 2
        z.dump(stuff)
        z.nl
        end
    attr_accessor :already_done,:indent,:recent_nl,:pass
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
    def dump(stuff)
        if @pass == 1
            if @already_done.has_key? stuff
                @used[stuff] = true
              else
                @already_done[stuff] = (@done_count += 1)
                stuff.to_zaml(self)
              end
          else
            if @already_done.has_key? stuff
                emit("*#{@already_done[stuff]}")
              else
                @already_done[stuff] = (@done_count += 1)
                emit("&#{@already_done[stuff]} ") if @used[stuff]
                stuff.to_zaml(self)
               end
           end
        end
    def nest(n=4)
        if block_given?
            @indent += n
            yield
            @indent -= n
        else
            @indent += n
        end
    end
    def unnest(n=4)
        @indent -= n
        end
    def nl(s='')
        #@dest.print("\n", ' '*@indent, s) unless @recent_nl or @pass == 1
        if @pass == 2
            @dest.print("\n", ' '*@indent) unless @recent_nl
            @dest.print(s)
        end
        @recent_nl = true
        end
    def emit(s)
        @dest.print(s) unless @pass == 1
        @recent_nl = false
        end
    end

class Object
    def to_zaml(z)
        z.emit("!ruby/object:#{self.class.name}")
        z.nest
        instance_variables.each { |v|
            z.nl
            z.dump(v[1..-1])
            z.emit(": ")
            z.dump(self.instance_variable_get(v))
            }
        z.unnest
        end
    end

class Numeric
    def to_zaml(z)
        z.emit(self.to_s)
        end
    end

class String
    def to_zaml(z)
        z.emit(self)
        end
    end
    
class Hash
    def to_zaml(z)
        #z.nest(2)
        keys.each { |k|
            z.nl
            z.dump(k)
            z.emit(": ")
            z.recent_nl = false
            z.nest(2) do
                z.dump(self[k])
            end
        }
        #z.unnest(2)
        end
    end

class Array
    def to_zaml(z)
        #z.nest(2)
        each { |v|
            z.nl("- ")
            z.dump(v)
            }
        #z.unnest(2)
        end
    end

class Symbol
    def to_zaml(z)
        z.emit(self.inspect)
        end
    end

################################################################
#
#   Unit testoids
#
################################################################

#class My_class
#    attr_accessor :fred,:gool,:me
#    def initialize
#        @fred = "Flintstone"
#        @qool =  "This is a gool string"
#        @me = self
#        end
#    end

#my_obj = My_class.new
#Zamlizer.dump([1,my_obj,2,"test",{ :bob => 6.8, :sam => 9.7}, 6,my_obj],STDOUT)

#require 'yaml'
#File.open('test.luz','w') do |output| 
#    File.open('demo.luz','r') do |input|
#        Zamlizer.dump(YAML::load(input), output)
#    end
#end

