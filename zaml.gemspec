Gem::Specification.new do |s|
  s.name         = "zaml"
  s.version      = "0.1.0"  # Please make sure this matches ZAML::VERSION
  s.date         = "2008-12-28"
  s.summary      = "A partial replacement for YAML, writen with speed and code clarity in mind."
  s.authors      = ["Markus Roberts", "Jesse Hallett", "Ian McIntosh", "Igal Koshevoy", "Simon Chiang"]
  s.email        = "zaml@googlegroups.com"
  s.homepage     = "http://github.com/hallettj/zaml"
  s.description  = "A partial replacement for YAML, writen with speed and code clarity in mind.  ZAML fixes one YAML bug (loading Exceptions) and provides a replacement for YAML.dump() unimaginatively called ZAML.dump(), which is faster on all known cases and an order of magnitude faster with complex structures."
  s.platform     = Gem::Platform::RUBY
  s.summary      = "zaml"
  s.require_path = "lib"
  s.has_rdoc     = true
  s.rdoc_options = ["--main", "README"]
  
  # list the files you want to include here. you can
  # check this manifest using 'rake :print_manifest'
  s.files = %W{
    README
    LICENSE
    lib/zaml.rb
    test/zaml_benchmarks.rb
    test/zaml_test.rb
  }
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    README
    LICENSE
  }

  s.test_files = %W{
    test/zaml_benchmarks.rb
    test/zaml_test.rb
  }
end
