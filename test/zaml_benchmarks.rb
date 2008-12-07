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
      n = 1000
      x.report('yaml') { n.times { YAML.dump(HASH, "") } }
      x.report('zaml') { n.times { ZAML.dump(HASH, "") } }
    end
  end

  def test_dump_time_for_complex_data
    puts
    puts "dump time for complex data:"
    Benchmark.bm do |x|
      n = 1000
      x.report('yaml') { n.times { YAML.dump(HASH, "") } }
      x.report('zaml') { n.times { ZAML.dump(HASH, "") } }
    end
  end

end
