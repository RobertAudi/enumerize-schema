# frozen_string_literal: true

require "pathname"

module EnumeratedAttribute
  class Configuration
    # @!attribute [r] default_config
    #
    # @return [Hash] the default config
    def default_config
      return @default_config if @default_config

      config = {}

      if defined?(Rails)
        config[:schema_file] = Rails.root.join("config", "enumerated_attributes.yml")
      else
        root_path = Pathname.new(defined?(Bundler) ? Bundler.root : Dir.pwd)

        config[:schema_file] = root_path.join("enumerated_attributes.yml")
      end

      @default_config = config.freeze
    end

    # @return [Pathname] the path to the schema file containing all the enum values
    def schema_file
      @schema_file ||= default_config[:schema_file]
    end

    # @param value [String, File, Pathname] the path to the schema file containing all the enum values
    # @raise [SchemaFileNotFoundError] if +value+ is not a file
    # @raise [SchemaFileNotReadableError] if +value+ is not a readable file
    # @return [Pathname] the path to the schema file containing all the enum values
    def schema_file=(value)
      if !File.file?(value)
        raise SchemaFileNotFoundError.new(schema_file: value)
      elsif !File.readable?(value)
        raise SchemaFileNotReadableError.new(schema_file: value)
      else
        @schema_file = Pathname.new(value)
      end
    end
  end
end
