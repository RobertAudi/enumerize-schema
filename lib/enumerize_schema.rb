# frozen_string_literal: true

require "yaml"
require "enumerize"
require "active_support/inflector/methods"

module EnumerizeSchema
  autoload :Configuration, "enumerize_schema/configuration"
  autoload :Version, "enumerize_schema/version"
  require_relative "./enumerize_schema/errors"

  # @!scope class

  # @!attribute [r] config
  # @return [Configuration] the EnumerizeSchema configuration object
  def self.config
    @config ||= Configuration.new
  end

  # Configure EnumerizeSchema.
  #
  # @example
  #   EnumerizeSchema.configure do |config|
  #     config.schema_file = Rails.root.join("config", "enumerize", "schema.yml")
  #   end
  #
  # @yieldparam config [Configuration] the EnumerizeSchema configuration object
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

  # The path of the schema file for the specific class extended by EnumerizeSchema.
  # This method will return +nil+ if a custom schema file was not specified.
  #
  # @example A class with a custom schema file
  #   class User
  #     extend EnumerizeSchema
  #
  #     self.enumerize_schema_file = Rails.root.join("config", "enumerize", "user.yml")
  #   end
  #
  #   User.enumerize_schema_file
  #   # => #<Pathname:config/enumerize/user.yml>
  #
  # @example Subsclasses inherit their parent's schema file
  #   class User
  #     extend EnumerizeSchema
  #
  #     self.enumerize_schema_file = Rails.root.join("config", "enumerize", "user.yml")
  #   end
  #
  #   class Member < User
  #   end
  #
  #   User.enumerize_schema_file
  #   # => #<Pathname:config/enumerize/user.yml>
  #   Member.enumerize_schema_file
  #   # => #<Pathname:config/enumerize/user.yml>
  #
  # @example Subsclasses can also use their own schema file instead of their parent's
  #   class User
  #     extend EnumerizeSchema
  #
  #     self.enumerize_schema_file = Rails.root.join("config", "enumerize", "user.yml")
  #   end
  #
  #   class Member < User
  #     self.enumerize_schema_file = Rails.root.join("config", "enumerize", "member.yml")
  #   end
  #
  #   User.enumerize_schema_file
  #   # => #<Pathname:config/enumerize/user.yml>
  #   Member.enumerize_schema_file
  #   # => #<Pathname:config/enumerize/member.yml>
  #
  # @example Subsclasses can also use the default schema file instead of their parent's
  #   class User
  #     extend EnumerizeSchema
  #
  #     self.enumerize_schema_file = Rails.root.join("config", "enumerize", "user.yml")
  #   end
  #
  #   class Member < User
  #     self.enumerize_schema_file = nil
  #   end
  #
  #   User.enumerize_schema_file
  #   # => #<Pathname:config/enumerize/user.yml>
  #   Member.enumerize_schema_file
  #   # => nil
  #
  # @example A class without a custom schema file
  #   class User
  #     extend EnumerizeSchema
  #   end
  #
  #   User.enumerize_schema_file
  #   # => nil
  #
  def enumerize_schema_file
    return @__enumerize_schema_file if instance_variable_defined?(:@__enumerize_schema_file)

    @__enumerize_schema_file = superclass.instance_variable_get(:@__enumerize_schema_file)
  end

  # Override the path to the enumerized attribute schema file for the current class.
  #
  # @example
  #   class User < ApplicationRecord
  #     include EnumerizeSchema
  #
  #     self.enumerize_schema_file = Rails.root.join("config", "enumerize", "user.yml")
  #   end
  #
  # @param value [String, File, Pathname] the path to the schema file containing all the enum values for the current class
  # @raise [SchemaFileNotFoundError] if +value+ is not a file
  # @raise [SchemaFileNotReadableError] if +value+ is not a readable file
  # @return [Pathname] the path to the schema file containing all the enum values for the current class
  def enumerize_schema_file=(value)
    if value.to_s.empty?
      @__enumerize_schema_file = nil
    elsif !File.file?(value)
      raise SchemaFileNotFoundError.new(schema_file: value)
    elsif !File.readable?(value)
      raise SchemaFileNotReadableError.new(schema_file: value)
    else
      @__enumerize_schema_file = Pathname.new(value)
    end
  end

  # @api private
  def enumerize_schema
    @__enumerize_schema ||=
      if enumerize_schema_file.to_s.empty?
        ::EnumerizeSchema.schema
      else
        YAML.load_file(enumerize_schema_file) || {}
      end
  end

  # @api private
  def enumerize_schema_attributes_scope
    @__enumerize_schema_attributes_scope ||= ActiveSupport::Inflector.underscore(name.to_s).split("/")
  end

  # Defines an enumerized attribute.
  #
  # @param attribute_name [Symbol] the name of the enumerized attribute
  # @param enumerize_options [Hash] options forwarded to +enumerize+
  # @raise [EnumerizeSchema::MissingValuesError] if the values for the enum are not found in the schema file
  # @return [void]
  #
  # @note This method is marked as +protected+ when added to the class, so it can't be used from outside that class.
  # @note If the +:in+ option is passed then this method will not check the schema file and forward all options to +enumerize+
  # @see  https://github.com/brainspec/enumerize Enumerize
  def attr_enum(attribute_name, **enumerize_options)
    if enumerize_options.include?(:in)
      enumerize(attribute_name, enumerize_options)
    else
      enum_values = Array(enumerize_schema.dig(*enumerize_schema_attributes_scope, attribute_name.to_s))

      if enum_values.empty?
        raise ::EnumerizeSchema::MissingValuesError.new(class_name: name, attribute_name: attribute_name)
      end

      enumerize(attribute_name, enumerize_options.merge(in: enum_values))
    end
  end
end
