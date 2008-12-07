require 'test/unit'
require 'benchmark'
require 'yaml'
require 'tempfile'

require 'zaml'

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

end