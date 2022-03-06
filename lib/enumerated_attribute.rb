# frozen_string_literal: true

require "yaml"
require "enumerize"
require "active_support/inflector/methods"

module EnumeratedAttribute
  autoload :Configuration, "enumerated_attribute/configuration"
  autoload :Version, "enumerated_attribute/version"
  require_relative "./enumerated_attribute/errors"

  require "enumerated_attribute/railtie" if defined?(::Rails::Railtie)

  # @!scope class

  # @!attribute [r] config
  # @return [Configuration] the EnumeratedAttribute configuration object
  def self.config
    @config ||= Configuration.new
  end

  # Configure EnumeratedAttribute.
  #
  # @example
  #   EnumeratedAttribute.configure do |config|
  #     config.schema_file = Rails.root.join("config", "enumerated_attributes", "schema.yml")
  #   end
  #
  # @yieldparam config [Configuration] the EnumeratedAttribute configuration object
  def self.configure
    yield(config)
  end

  # @private
  def self.configured?
    !!@__configured
  end

  # @private
  def self.schema
    @__schema ||=
      if config.schema_file.to_s.empty?
        {}
      elsif !File.file?(config.schema_file)
        raise SchemaFileNotFoundError.new(schema_file: config.schema_file)
      elsif !File.readable?(config.schema_file)
        raise SchemaFileNotReadableError.new(schema_file: config.schema_file)
      else
        YAML.load_file(config.schema_file) || {}
      end
  end

  # @private
  def self.extended(base)
    unless base.singleton_class.ancestors.include?(Enumerize)
      base.extend(Enumerize)
    end

    class << base
      protected :attr_enum
    end
  end

  # The path of the schema file for the specific class extended by EnumeratedAttribute.
  # This method will return +nil+ if a custom schema file was not specified.
  #
  # @example A class with a custom schema file
  #   class User
  #     extend EnumeratedAttribute
  #
  #     self.enumerated_attributes_schema_file = Rails.root.join("config", "enumerated_attribute", "user.yml")
  #   end
  #
  #   User.enumerated_attributes_schema_file
  #   # => #<Pathname:config/enumerated_attribute/user.yml>
  #
  # @example Subsclasses inherit their parent's schema file
  #   class User
  #     extend EnumeratedAttribute
  #
  #     self.enumerated_attributes_schema_file = Rails.root.join("config", "enumerated_attribute", "user.yml")
  #   end
  #
  #   class Member < User
  #   end
  #
  #   User.enumerated_attributes_schema_file
  #   # => #<Pathname:config/enumerated_attribute/user.yml>
  #   Member.enumerated_attributes_schema_file
  #   # => #<Pathname:config/enumerated_attribute/user.yml>
  #
  # @example Subsclasses can also use their own schema file instead of their parent's
  #   class User
  #     extend EnumeratedAttribute
  #
  #     self.enumerated_attributes_schema_file = Rails.root.join("config", "enumerated_attribute", "user.yml")
  #   end
  #
  #   class Member < User
  #     self.enumerated_attributes_schema_file = Rails.root.join("config", "enumerated_attribute", "member.yml")
  #   end
  #
  #   User.enumerated_attributes_schema_file
  #   # => #<Pathname:config/enumerated_attribute/user.yml>
  #   Member.enumerated_attributes_schema_file
  #   # => #<Pathname:config/enumerated_attribute/member.yml>
  #
  # @example Subsclasses can also use the default schema file instead of their parent's
  #   class User
  #     extend EnumeratedAttribute
  #
  #     self.enumerated_attributes_schema_file = Rails.root.join("config", "enumerated_attribute", "user.yml")
  #   end
  #
  #   class Member < User
  #     self.enumerated_attributes_schema_file = nil
  #   end
  #
  #   User.enumerated_attributes_schema_file
  #   # => #<Pathname:config/enumerated_attribute/user.yml>
  #   Member.enumerated_attributes_schema_file
  #   # => nil
  #
  # @example A class without a custom schema file
  #   class User
  #     extend EnumeratedAttribute
  #   end
  #
  #   User.enumerated_attributes_schema_file
  #   # => nil
  #
  def enumerated_attributes_schema_file
    return @__enumerated_attributes_schema_file if instance_variable_defined?(:@__enumerated_attributes_schema_file)

    @__enumerated_attributes_schema_file = superclass.instance_variable_get(:@__enumerated_attributes_schema_file)
  end

  # Override the path to the enumerated attribute schema file for the current class.
  #
  # @example
  #   class User < ApplicationRecord
  #     include EnumeratedAttribute
  #
  #     self.enumerated_attributes_schema_file = Rails.root.join("config", "enumerated_attributes", "user.yml")
  #   end
  #
  # @param value [String, File, Pathname] the path to the schema file containing all the enum values for the current class
  # @raise [SchemaFileNotFoundError] if +value+ is not a file
  # @raise [SchemaFileNotReadableError] if +value+ is not a readable file
  # @return [Pathname] the path to the schema file containing all the enum values for the current class
  def enumerated_attributes_schema_file=(value)
    if value.to_s.empty?
      @__enumerated_attributes_schema_file = nil
    elsif !File.file?(value)
      raise SchemaFileNotFoundError.new(schema_file: value)
    elsif !File.readable?(value)
      raise SchemaFileNotReadableError.new(schema_file: value)
    else
      @__enumerated_attributes_schema_file = Pathname.new(value)
    end
  end

  # @api private
  def enumerated_attributes_schema
    @__enumerated_attributes_schema ||=
      if enumerated_attributes_schema_file.to_s.empty?
        ::EnumeratedAttribute.schema
      else
        YAML.load_file(enumerated_attributes_schema_file) || {}
      end
  end

  # @api private
  def enumerated_attributes_scope
    @__enumerated_attributes_scope ||= ActiveSupport::Inflector.underscore(name.to_s).split("/")
  end

  # Defines an enumerated attribute.
  #
  # @param attribute_name [Symbol] the name of the enumerated attribute
  # @param enumerize_options [Hash] options forwarded to +enumerize+
  # @raise [EnumeratedAttribute::MissingValuesError] if the values for the enum are not found in the schema file
  # @return [void]
  #
  # @note This method is marked as +protected+ when added to the class, so it can't be used from outside that class.
  # @note If the +:in+ option is passed then this method will not check the schema file and forward all options to +enumerize+
  # @see  https://github.com/brainspec/enumerize Enumerize
  def attr_enum(attribute_name, **enumerize_options)
    if enumerize_options.include?(:in)
      enumerize(attribute_name, enumerize_options)
    else
      enum_values = Array(enumerated_attributes_schema.dig(*enumerated_attributes_scope, attribute_name.to_s))

      if enum_values.empty?
        raise ::EnumeratedAttribute::MissingValuesError.new(class_name: name, attribute_name: attribute_name)
      end

      enumerize(attribute_name, enumerize_options.merge(in: enum_values))
    end
  end
end
