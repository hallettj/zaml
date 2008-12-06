require "zaml"

################################################################
#
#   Behavior for custom classes
#
################################################################

class Object
  def to_yaml_properties
    instance_variables.sort        # Default YAML behavior
  end
  
  def to_zaml(z)
    z.first_time_only(self) {
      z.nested(zamlized_class_name(Object)) {
        instance_variables = to_yaml_properties
        if instance_variables.empty?
          z.emit("{}\n")
        else
          instance_variables.each { |v|
            z.nl
            v[1..-1].to_zaml(z)       # Remove leading '@'
            z.emit(': ')
            instance_variable_get(v).to_zaml(z)
          }
        end
      }
    }
  end
end

class Exception
  def to_zaml(z)
    z.emit(zamlized_class_name(Exception))
    z.nested {
      z.nl("message: ")
      message.to_zaml(z)
    }
  end
end
