require File.dirname(__FILE__) + "/../lib/zaml"
require 'test/unit'
require 'yaml'

class ZamlLoadTest < Test::Unit::TestCase
  
  #
  # compatible cases
  #
  
  non_nested_array = ['str', :sym, true, false, 100, 1.1]
  non_nested_hash = {
    'str' => 'value', 
    :sym => :value, 
    :true => true,
    :false => false,
    :int => 100,
    :float => 1.1
  }
  
  TEST_CASES = {}
  TEST_CASES["empty_string"] = ""
  TEST_CASES["array"] = non_nested_array.to_yaml
  TEST_CASES["hash"] = non_nested_hash.to_yaml
  TEST_CASES["nested_hash"] = non_nested_hash.merge(
    :hash => non_nested_hash, 
    :array => non_nested_array
  ).to_yaml
  TEST_CASES["yaml_with_comments"] = %q{
key: value
# this should be ignored

another: value
}
  
  TEST_CASES.each_pair do |name, test_case|
    define_method("test_load_compatibility_for_#{name}") do
      assert_equal YAML.load(test_case), ZAML.load(test_case)
    end
  end
  
  #
  # fail cases
  #
  
  FAIL_CASES = {}
  FAIL_CASES["hash_and_array_mix"] = %q{
key: value
- 1
- 2
- 3
}
  
  FAIL_CASES.each_pair do |name, test_case|
    define_method("test_load_fails_for_#{name}") do
      assert_raise(RuntimeError) { ZAML.load(test_case) }
    end
  end
  
  def test_load_gemrc
    gemrc = %Q{
---
:benchmark: false
:bulk_threshold: 1000
:verbose: true
:update_sources: true
:sources:
- http://gems.rubyforge.org/
- http://gems.github.com
:backtrace: false
}

    expected = {
      :benchmark => false,
      :bulk_threshold => 1000,
      :verbose => true,
      :update_sources => true,
      :sources => ['http://gems.rubyforge.org/', 'http://gems.github.com'],
      :backtrace => false
    }
    
    assert_equal expected, ZAML.load(gemrc)
  end
  
end