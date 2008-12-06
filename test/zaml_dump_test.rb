require File.dirname(__FILE__) + "/../lib/zaml"
require 'test/unit'
require 'tempfile'
require 'yaml'

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

class ZamlDumpTest < Test::Unit::TestCase

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
  DATA = {
    :data => [1, my_range, my_obj, my_bob, my_dull_object, 2, 'test', "   funky\n test\n", true, false, {my_obj => 'obj is the key!'}, {:bob => 6.8, :sam => 9.7, :subhash => {:sh1 => 'one', :sh2 => 'two'}}, 6, my_bob, my_obj, my_range, 'bob', 1..10, 0...8],
    :more_data => [:a_regexp =>/a.*(b+)/im,:an_exception => my_exception,:a_runtime_error => my_runtime_error, :a_long_string => wright_joke],
    :nested_arrays => [[:one, 'One'],[:two, 'Two'],a_box_of_cheese,[:three, 'Three'],[:four, 'Four'],a_box_of_cheese,[:five, 'Five'],[:six, 'Six']]
  }
  
  def compatibility_test(obj, msg=nil)
    dump = ZAML.dump(obj)
    
    assert_equal YAML.dump(obj), dump, msg
    assert_equal obj, YAML.load(dump), msg
  end
  
  def test_dump_compatibility_for_simple_hash
    compatibility_test({:key => 'value'})
  end
  
  def test_dump_compatibility_for_simple_array
    compatibility_test([1,2,3])
  end
  
  # def test_dump_compatibility
  #   dump = ZAML.dump(DATA)
  #   assert_equal YAML.dump(DATA), dump
  #   assert_equal DATA, YAML.load(dump)
  # end
    
  # elsif ARGV[0] == 'StephenCelisTest'
  #   require 'benchmark'
  #   Benchmark.bm do |x|
  #     n = 10000
  #     x.report('nil ') { n.times {           []; IO.new(1)  } }
  #     x.report('yaml') { n.times { YAML.dump([], IO.new(1)) } }
  #     x.report('zaml') { n.times { ZAML.dump([], IO.new(1)) } }
  #   end
  # else
  #   reps = ARGV[0] ? ARGV[0].to_i : 0
  #   of_what = ARGV[1]
  #   big_data = []
  #   (1..reps).each { |i| 
  #     if of_what
  #       big_data << eval(of_what)
  #     else
  #       big_data << i
  #       big_data << My_class.new
  #     end
  #   }
  #   start = Time.now
  #   File.open('tmp-zaml','w') { |output| 
  #     ZAML.dump(big_data, output)
  #   }
  #   print "#{reps} of #{of_what} took #{Time.now-start} with zaml.\n"
  #   start = Time.now
  #   File.open('tmp-yaml','w') { |output| 
  #     YAML.dump(big_data, output)
  #   }
  #   print "#{reps} of #{of_what} took #{Time.now-start} with yaml.\n"
  # end

end