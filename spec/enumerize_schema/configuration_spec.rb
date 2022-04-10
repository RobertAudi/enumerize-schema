# frozen_string_literal: true

RSpec.describe EnumerizeSchema::Configuration do
  subject(:configuration) { described_class.new }

  describe "[#default_config]" do
    it "returns the default configuration" do
      expect(configuration.default_config).to eq({
        schema_file: Bundler.root.join("enumerize.yml")
      })
    end

    it "is frozen" do
      expect(configuration.default_config).to be_frozen
    end
  end

  describe "[#schema_file]" do
    specify "it returns the default path to the schema file" do
      expect(configuration.schema_file).to eq(Bundler.root.join("enumerze.yml"))
    end
  end

  describe "[#schema_file=]" do
    let(:schema_file) { Bundler.root.join("spec", "fixtures", "enumerize.yml") }

    specify "it sets the path to the schema file" do
      expect { configuration.schema_file = schema_file }
        .to change { configuration.schema_file }.to(schema_file)
    end

    context "when the file is not a file" do
      let(:invalid_schema_file) { Bundler.root }

      specify "it raises an error" do
        expect { configuration.schema_file = invalid_schema_file }.to raise_error(EnumerizeSchema::SchemaFileNotFoundError) do |error|
          expect(error.schema_file).to eq(invalid_schema_file)
        end
      end
    end

    context "when the file is not a readable" do
      let(:unreadable_schema_file) { Bundler.root.join("spec", "fixtures", "enumerize.yml") }

      before do
        allow(File).to receive(:readable?).with(unreadable_schema_file).and_return(false)
      end

      specify "it raises an error" do
        expect { configuration.schema_file = unreadable_schema_file }.to raise_error(EnumerizeSchema::SchemaFileNotReadableError) do |error|
          expect(error.schema_file).to eq(unreadable_schema_file)
        end
      end
    end
  end
end
