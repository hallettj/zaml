require 'test/unit'
require 'yaml'

require "zaml/objects"
require 'yaml_load_exception_patch'

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

class ZamlObjectsTest < Test::Unit::TestCase

  # bare objects can't be directly compared because their
  # object ids are different.
  def object_dump_test(obj)
    dump = ZAML.dump(obj)
    assert_equal YAML.dump(obj), dump, "Object dump discrepancy"
  end
  
  # NOTE Exception does not reload an equal
  # object, even with the load_exception_patch.
  # Hence, this test is customized to check the
  # essential parts.
  def exception_dump_test(obj)
    dump = ZAML.dump(obj)
    assert_equal YAML.dump(obj), dump, "Exception dump discrepancy"
    
    reloaded = YAML.load(dump)
    assert_equal obj.class, reloaded.class, "Exception reload discrepancy"
    assert_equal obj.message, reloaded.message, "Exception reload discrepancy"
  end
  
  #
  # dump tests
  # 
  
  def test_dump_object
    object_dump_test(Object.new)
    object_dump_test(My_class.new)
  end
  
  def test_dump_exception
    exception_dump_test(Exception.new('error message'))
    exception_dump_test(ArgumentError.new('error message'))
  end
  
  #
  # dump objects tests
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
  
  # def test_dump_dump
  #   dump_test(COMPLEX_DATA)
  # end

end