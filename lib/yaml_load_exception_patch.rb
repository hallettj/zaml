require 'yaml'

class Exception
  # Monkey patch for buggy Exception restore in YAML
  #
  #     This makes it work for now but is not very future-proof; if things
  #     change we'll most likely want to remove this.  To mitigate the risks
  #     as much as possible, we test for the bug before appling the patch.
  #
  if yaml_new(self, :tag, "message" => "blurp").message != "blurp"
    def self.yaml_new( klass, tag, val )
      o = YAML.object_maker( klass, {} ).exception(val.delete( 'message'))
      val.each_pair do |k,v|
        o.instance_variable_set("@#{k}", v)
      end
      o
    end
  end
end