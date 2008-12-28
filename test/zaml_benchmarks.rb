require 'test/unit'
require 'benchmark'
require 'yaml'
require 'tempfile'

require 'zaml'

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

class ZamlBenchmarks < Test::Unit::TestCase
    #
    # dump various data tests
    #
    my_range = 7..13
    my_obj = My_class.new
    my_dull_object = Object.new
    my_bob = 'bob'
    my_exception = Exception.new("Error message")
    my_runtime_error = RuntimeError.new("This is a runtime error exception")
    wright_joke = %q{
  
      I was in the grocery store. I saw a sign that said "pet supplies". 
  
      So I did.
  
      Then I went outside and saw a sign that said "compact cars".
  
      -- Steven Wright
    }
    a_box_of_cheese = [:cheese]
    
    DATA = [1, my_range, my_obj, my_bob, my_dull_object, 2, 'test', "   funky\n test\n", true, false, 
      {my_obj => 'obj is the key!'}, 
      {:bob => 6.8, :sam => 9.7, :subhash => {:sh1 => 'one', :sh2 => 'two'}}, 
      6, my_bob, my_obj, my_range, 'bob', 1..10, 0...8]
    
    MORE_DATA = [{
      :a_regexp => /a.*(b+)/im,
      :an_exception => my_exception,
      :a_runtime_error => my_runtime_error, 
      :a_long_string => wright_joke}]
    
    NESTED_ARRAYS = [
      [:one, 'One'],
      [:two, 'Two'],
      a_box_of_cheese,
      [:three, 'Three'],
      [:four, 'Four'],
      a_box_of_cheese,
      [:five, 'Five'],
      [:six, 'Six']]
      
    COMPLEX_DATA = {
      :data => DATA,
      :more_data => MORE_DATA,
      :nested_arrays => NESTED_ARRAYS
    }
  
    HASH = {
      'str' => 'value', 
      :sym => :value, 
      :true => true,
      :false => false,
      :int => 100,
      :float => 1.1
    }
    def test_dump_time
        puts
        puts "dump:"
        Benchmark.bm do |x|
            n = 100
            GC.start; x.report('yaml') { n.times { YAML.dump(HASH, "") } }
            GC.start; x.report('zaml') { n.times { ZAML.dump(HASH, "") } }
            end
        end
    def test_dump_time_for_complex_data
        puts
        puts "dump time for complex data:"
        Benchmark.bm do |x|
            n = 100
            GC.start; x.report('yaml') { n.times { YAML.dump(COMPLEX_DATA, "") } }
            GC.start; x.report('zaml') { n.times { ZAML.dump(COMPLEX_DATA, "") } }
            end
        end
    def test_dump_time_for_big_data
        puts
        puts "dump time for big data:"
        Benchmark.bm do |x|
            n = 100
            [10,100,1000].each { |s|
                big_data = (1..s).collect { |i| [My_class.new,COMPLEX_DATA] }
                print "s = #{s}\n"
                GC.start; x.report('yaml') { n.times { YAML.dump(big_data, "") } }
                GC.start; x.report('zaml') { n.times { ZAML.dump(big_data, "") } }
                n = n/10
                }
            end
        end
    def test_deeply_nested_arrays
        branch = []
        root = [branch]
        (1..10000).each { |i|
            case
              when i % 3 == 0   then branch << i
              when 1 % 5 == 0   then branch << [i]
              else                   branch = [];     root << branch
              end
            }
        puts
        puts "dump time for deeply nested arrays:"
        Benchmark.bm do |x|
            n = 10
            GC.start; x.report('yaml') { n.times { YAML.dump(root, "") } }
            GC.start; x.report('zaml') { n.times { ZAML.dump(root, "") } }
            end
        end
    def test_lots_of_back_refs
        leaves = ['a string',[:an,:array,:of,:symbols],{:this=>'is a hash'},0..9,'a'*10000]
        branch = []
        root = [branch]
        (1..500000).each { |i|
            case
              when i % 3 == 0   then branch << leaves[i % leaves.length]
              when 1 % 5 == 0   then branch << leaves
              when 1 % 2 == 0   then branch << root[i % root.length]
              else                   branch = []; root << branch
              end
            }
        puts
        puts "dump time for lots of back references:"
        Benchmark.bm do |x|
            GC.start; x.report('yaml') { YAML.dump(root, "") }
            GC.start; x.report('zaml') { ZAML.dump(root, "") }
            end
        end
    class A_node
        attr_accessor :value,:factors,:gcd_pairs
        def initialize(v)
            @value = v
            @factors = []
            @gcd_pairs = []
            end
        end
    def gcd(a,b)
        (b == 0) ? a : gcd(b,a % b)
        end
    def test_nest_of_objects
        my_mess = []
        n = 1000
        (0..n).each { |i| my_mess << A_node.new(i) }
        (1..n).each { |i| 
            (2..(n/i)).each { |j| my_mess[j].factors << my_mess[i]  }
            (i..n).each { |j| my_mess[gcd(i,j)].gcd_pairs << [i,j] }
            }
        puts
        puts "dump time for big, tangled nest of objects:"
        Benchmark.bm do |x|
            GC.start; x.report('yaml') { YAML.dump(my_mess, "") }
            GC.start; x.report('zaml') { ZAML.dump(my_mess, "") }
            end
        end
    end
