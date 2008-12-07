require 'test/unit'
require 'yaml'
require 'yaml_load_exception_patch'

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

class ZamlDumpTest < Test::Unit::TestCase
  
  HASH = {
    :nil => nil,
    :sym => :value, 
    :true => true,
    :false => false,
    :int => 100,
    :float => 1.1,
    :regexp => /abc/,
    'str' => 'value', 
    :range => 1..10
  }
  
  ARRAY = [nil, :sym, true, false, 100, 1.1, /abc/, 'str', 1..10]
  
  #
  # some helpers
  #
  
  # tests for exact YAML dump equality.  returns the ZAML dump
  def yaml_equality_test(obj)
    dump = ZAML.dump(obj)
    assert_equal YAML.dump(obj), dump, "Dump discrepancy"
    dump
  end
  
  # tests a round-trip dump, and exact YAML equality
  def dump_test(obj)
    dump = yaml_equality_test(obj)
    assert_equal obj, YAML.load(dump), "Reload discrepancy"
  end
  
  # NOTE Exception does not reload an equal
  # object, even with the load_exception_patch.
  # Hence, this test is customized to check the
  # essential parts.
  def exception_dump_test(obj)
    dump = yaml_equality_test(obj)
    
    reloaded = YAML.load(dump)
    assert_equal obj.class, reloaded.class, "Exception reload discrepancy"
    assert_equal obj.message, reloaded.message, "Exception reload discrepancy"
  end
  
  #
  # dump tests
  #
  
  def test_dump_object
    yaml_equality_test(Object.new)
    yaml_equality_test(My_class.new)
  end
  
  def test_dump_nil
    dump_test(nil)
  end
  
  def test_dump_symbol
    dump_test(:sym)
  end
  
  def test_dump_true
    dump_test(true)
  end
  
  def test_dump_false
    dump_test(false)
  end
  
  def test_dump_numeric
    dump_test(1)
    dump_test(1.1)
  end
  
  def test_dump_exception
    exception_dump_test(Exception.new('error message'))
    exception_dump_test(ArgumentError.new('error message'))
  end
  
  def test_dump_regexp
    dump_test(/abc/)
    dump_test(/a.*(b+)/im)
  end
  
  def test_dump_string
    dump_test('str')
    dump_test("   leading and trailing whitespace   ")

    dump_test("a string \n with newline")
    dump_test("a string with 'quotes'")
    dump_test("a string with \"double quotes\"")
    dump_test("a string with \\ escape")
    
    dump_test("a really long string" * 10)
    dump_test("a really long string \n with newline" * 10)
    dump_test("a really long string with 'quotes'" * 10)
    dump_test("a really long string with \"double quotes\"" * 10)
    dump_test("a really long string with \\ escape" * 10)
    
    dump_test("string with binary data \x00 \x01 \x02")
    dump_test("   funky\n test\n")
  end
  
  # def test_dump_time
  #   dump_test(Time.now)
  # end
  # 
  # def test_dump_date
  #   dump_test(Date.strptime('2008-08-08'))
  # end
  
  def test_dump_range
    dump_test(1..10)
    dump_test('a'...'b')
  end
  
  #
  # hash
  #
  
  def test_dump_simple_hash
    dump_test({:key => 'value'})
  end
  
  def test_dump_hash
    dump_test(HASH)
  end
  
  def test_dump_simple_nested_hash
    dump_test({:hash => {:key => 'value'}, :array => [1,2,3]})
  end
  
  def test_dump_nested_hash
    dump_test(HASH.merge(:hash => {:hash => {:key => 'value'}}, :array => [[1,2,3]]))
  end
  
  def test_dump_self_referential_hash
    array = ARRAY + [ARRAY]
    dump_test(HASH.merge(:hash => HASH, :array => array))
  end
  
  # def test_dump_singlular_self_referential_hash
  #   hash = {}
  #   hash[hash] = hash
  #   assert_equal YAML.dump(hash), ZAML.dump(hash), "Dump discrepancy"
  # end
  
  #
  # array
  #
  
  def test_dump_simple_array
    dump_test([1,2,3])
  end
  
  def test_dump_array
    dump_test(ARRAY)
  end
  
  def test_dump_simple_nested_array
    dump_test([{:key => 'value'}, [1,2,3]])
  end
  
  def test_dump_nested_array
    dump_test(ARRAY.concat([{:array => [1,2,3]}, [[1,2,3]]]))
  end
  
  def test_dump_self_referential_array
    array = ARRAY + [ARRAY, HASH.merge(:hash => HASH)]
    dump_test(array)
  end
  
  # def test_dump_singlular_self_referential_array
  #   array = []
  #   array << array
  #   assert_equal YAML.dump(array), ZAML.dump(array), "Dump discrepancy"
  # end
  
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
  
  def test_dump_DATA
    yaml_equality_test(DATA)
  end
  
  def test_dump_MORE_DATA
    yaml_equality_test(MORE_DATA)
  end
  
  def test_dump_NESTED_ARRAYS
    yaml_equality_test(NESTED_ARRAYS)
  end
  
  def test_dump_COMPLEX_DATA
    yaml_equality_test(COMPLEX_DATA)
  end
  
end