Gem::Specification.new do |s|
  s.name = "zaml"
  s.version = "0.1.0"
  s.authors = ["Jesse Hallett", "Simon Chiang"]
  #s.email = "your.email@pubfactory.edu"
  s.homepage = "http://github.com/hallettj/zaml/tree/master"
  s.platform = Gem::Platform::RUBY
  s.summary = "zaml"
  s.require_path = "lib"
  s.has_rdoc = true
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    README
    LICENSE
  }
  
  # list the files you want to include here. you can
  # check this manifest using 'rake :print_manifest'
  s.files = %W{
    lib/zaml.rb
  }
end