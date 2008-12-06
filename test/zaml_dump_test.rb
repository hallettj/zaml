require 'test/unit'
require 'yaml'

require 'zaml'

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
  
  # a helper to test the round-trip dump
  def dump_test(obj)
    dump = ZAML.dump(obj)
    
    assert_equal YAML.dump(obj), dump, "Dump discrepancy"
    assert_equal obj, YAML.load(dump), "Reload discrepancy"
  end
  
  #
  # dump tests
  # 
  
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
  
end