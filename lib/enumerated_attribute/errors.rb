# @!group Errors
module EnumeratedAttribute
  class SchemaFileNotFoundError < RuntimeError
    # @return [String, nil] the schema file that caused the error
    attr_reader :schema_file

    # @param schema_file [String, nil] the schema file that caused the error
    def initialize(schema_file:)
      @schema_file = schema_file

      super("Unable to locate the schema file: #{schema_file.inspect}")
    end
  end

  class SchemaFileNotReadableError < RuntimeError
    # @return [String, nil] the schema file that caused the error
    attr_reader :schema_file

    # @param schema_file [String, nil] the schema file that caused the error
    def initialize(schema_file:)
      @schema_file = schema_file

      super("Unable to read the schema file #{schema_file.inspect}")
    end
  end

  class MissingValuesError < KeyError
    # @return [String] the name of the class where the enum is defined
    attr_reader :class_name

    # @return [String] the name of the enum attribute
    attr_reader :attribute_name

    # @param class_name [String] the name of the class where the enum is defined
    # @param attribute_name [String] the name of the enum attribute
    def initialize(class_name:, attribute_name:)
      @class_name = class_name
      @attribute_name = attribute_name

      super("Enumerated values missing for attribute: #{class_name}##{attribute_name}")
    end
  end
end
# @!endgroup
