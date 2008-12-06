require 'test/unit'
require 'yaml'

require 'zaml'

class ZamlDumpTest < Test::Unit::TestCase
  
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
  
  def test_dump_simple_hash
    dump_test({:key => 'value'})
  end
  
  def test_dump_simple_array
    dump_test([1,2,3])
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
  
end