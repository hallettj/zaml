Gem::Specification.new do |s|
  s.name        = "zaml"
  s.version     = "0.071"
  s.date        = "2008-12-06"
  s.summary     = "A partial replacement for YAML, writen with speed and code clarity in mind."
  s.email       = "zaml@sitr.us"
  s.homepage    = "http://github.com/hallettj/zaml"
  s.description = "A partial replacement for YAML, writen with speed and code clarity in mind.  ZAML fixes one YAML bug (loading Exceptions) and provides a replacement for YAML.dump() unimaginatively called ZAML.dump(), which is faster on all known cases and an order of magnitude faster with complex structures."
  s.has_rdoc    = false
  s.authors     = ["Markus Roberts", "Jesse Hallett", "Ian McIntosh", "Igal Koshevoy"]
  s.files       = ["zaml.rb", "README", "LICENSE"]
end
