require File.dirname(__FILE__) + "/../lib/zaml"
require 'test/unit'
require 'benchmark'
require 'yaml'
require 'tempfile'

class ZamlBenchmarks < Test::Unit::TestCase
  
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
  
  def test_load_time
    puts
    puts "load:"
    Benchmark.bm do |x|
      n = 1000
      str = HASH.to_yaml
      x.report('yaml') { n.times { YAML.load(str) } }
      x.report('zaml') { n.times { ZAML.load(str) } }
    end
  end
  
  def test_require_and_load_time
    tempfile = Tempfile.new("load_time")
    tempfile << HASH.to_yaml
    tempfile.close
    
    cmd = %Q{ruby -e 'start = Time.now; require "%s"; %s.load_file("#{tempfile.path}"); puts "%s:  \#{Time.now-start}"'}
    
    puts
    puts "require and load:"
    system(cmd % ['yaml', 'YAML', 'yaml'])
    system(cmd % ['lib/zaml', 'ZAML', 'zaml'])
  end
  
end