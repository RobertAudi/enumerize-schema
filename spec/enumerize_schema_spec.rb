# frozen_string_literal: true

class FakeSuperhero
  extend EnumerizeSchema

  self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "enumerize.yml")

  attr_enum :powers, default: "none"
end

RSpec.describe EnumerizeSchema do
  describe "attr_enum :gender, default: :other" do
    it {
      expect(FakeSuperhero.new)
        .to enumerize(:powers)
        .in(:lying, :flexing, :none)
        .with_default(:none)
    }
  end

  context "when the schema file is missing" do
    specify "it raises an error" do
      expect {
        Class.new(FakeSuperhero) { self.enumerize_schema_file = "invalid_file.json" }
      }.to raise_error(EnumerizeSchema::SchemaFileNotFoundError)
    end
  end

  context "when the enumerized values are missing for an attribute" do
    specify "it raises an error" do
      expect {
        Class.new(FakeSuperhero) { attr_enum :disguise }
      }.to raise_error(EnumerizeSchema::MissingValuesError)
    end

    context "when the :in option is passed" do
      specify "doesn't raise an error" do
        expect {
          Class.new(FakeSuperhero) { attr_enum :disguise, in: %i[clown ninja pirate] }
        }.to_not raise_error
      end

      it {
        expect(Class.new(FakeSuperhero) { attr_enum :disguise, in: %i[clown ninja pirate] }.new)
          .to enumerize(:disguise)
          .in(:clown, :ninja, :pirate)
      }
    end
  end

  describe "[.enumerize_schema_file]" do
    context "when the schema file is not overriden in the class" do
      specify "it returns nil" do
        expect(Class.new {
          extend EnumerizeSchema
        }.enumerize_schema_file).to be(nil)
      end
    end

    context "when the schema file is overriden in the class" do
      specify "it returns the path to the custom schema file" do
        expect(Class.new {
          extend EnumerizeSchema

          self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "empty.yml")
        }.enumerize_schema_file).to eq(Bundler.root.join("spec", "fixtures", "empty.yml"))
      end
    end

    context "when the schema file is overriden in the superclass" do
      context "when the schema file is not overriden in the subclass" do
        specify "it returns the path to the custom schema file defined in the superclass" do
          expect(Class.new(FakeSuperhero).enumerize_schema_file)
            .to eq(FakeSuperhero.enumerize_schema_file)
        end
      end

      context "when the schema file is overriden in the subclass" do
        specify "it returns the path to the custom schema file defined in the subclass" do
          expect(Class.new(FakeSuperhero) {
            self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "empty.yml")
          }.enumerize_schema_file).to eq(Bundler.root.join("spec", "fixtures", "empty.yml"))
        end
      end

      context "when the schema file is set to nil in the subclass" do
        specify "it returns nil" do
          expect(Class.new(FakeSuperhero) {
            self.enumerize_schema_file = nil
          }.enumerize_schema_file).to be(nil)
        end
      end
    end
  end

  describe "[.enumerize_schema_file=]" do
    context "when the new value is not a file" do
      let(:invalid_schema_file) { Bundler.root }

      specify "it raises an error" do
        expect {
          Class.new { extend EnumerizeSchema }.enumerize_schema_file = invalid_schema_file
        }.to raise_error(EnumerizeSchema::SchemaFileNotFoundError) do |error|
          expect(error.schema_file).to eq(invalid_schema_file)
        end
      end
    end

    context "when the new value is not a readable file" do
      let(:unreadable_schema_file) { Bundler.root.join("spec", "fixtures", "enumerize.yml") }

      before do
        allow(File).to receive(:readable?).with(unreadable_schema_file).and_return(false)
      end

      specify "it raises an error" do
        expect {
          Class.new { extend EnumerizeSchema }.enumerize_schema_file = unreadable_schema_file
        }.to raise_error(EnumerizeSchema::SchemaFileNotReadableError) do |error|
          expect(error.schema_file).to eq(unreadable_schema_file)
        end
      end
    end

    context "when the new value is a readable file" do
      let(:schema_file) { Bundler.root.join("spec", "fixtures", "enumerize.yml") }

      specify "it sets the path to the schema file" do
        klass = Class.new { extend EnumerizeSchema }

        expect { klass.enumerize_schema_file = schema_file }
          .to change { klass.enumerize_schema_file }.to(schema_file)
      end

      context "when the value is nil" do
        specify "it sets the path to nil" do
          klass = Class.new {
            extend EnumerizeSchema

            self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "enumerize.yml")
          }

          expect { klass.enumerize_schema_file = nil }
            .to change { klass.enumerize_schema_file }
            .from(Bundler.root.join("spec", "fixtures", "enumerize.yml")).to(nil)
        end
      end
    end

    context "when a class has a custom schema file" do
      context "when a subclass sets the value to nil" do
        let!(:klass) do
          Class.new {
            extend EnumerizeSchema

            self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "enumerize.yml")
          }
        end

        specify "it doesn't change the parent's schema file" do
          expect {
            Class.new(klass) { self.enumerize_schema_file = nil }
          }.to_not change { klass.enumerize_schema_file }
        end

        specify "it sets the subclass' schema to nil" do
          expect(Class.new(klass) {
            self.enumerize_schema_file = nil
          }.enumerize_schema_file).to be(nil)
        end
      end

      context "when a subclass sets the value to another path" do
        let!(:klass) do
          Class.new {
            def self.name
              "FakeUser"
            end

            extend EnumerizeSchema

            self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "fake_user.yml")

            attr_enum :gender
          }
        end

        specify "it doesn't change the parent's schema file" do
          expect {
            Class.new(klass) {
              def self.name
                "FakeMember"
              end

              self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "fake_member.yml")

              attr_enum :plan
            }
          }.to_not change { klass.enumerize_schema_file }
        end

        specify "it sets the subclass' schema to the new value" do
          expect(Class.new(klass) {
            def self.name
              "FakeMember"
            end

            self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "fake_member.yml")

            attr_enum :plan
          }.enumerize_schema_file).to eq(Bundler.root.join("spec", "fixtures", "fake_member.yml"))
        end
      end

      context "when a class and its subclass have different schema files" do
        context "when the parent class changes its schema file" do
          let(:parent_class) do
            Class.new {
              def self.name
                "FakeUser"
              end

              extend EnumerizeSchema

              self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "fake_user.yml")

              attr_enum :gender
            }
          end

          let(:child_class) do
            Class.new(parent_class) {
              def self.name
                "FakeMember"
              end

              self.enumerize_schema_file = Bundler.root.join("spec", "fixtures", "fake_member.yml")

              attr_enum :plan
            }
          end

          let(:old_schema) { Bundler.root.join("spec", "fixtures", "fake_user.yml") }
          let(:new_schema) { Bundler.root.join("spec", "fixtures", "enumerize.yml") }

          specify "it doesn't change the subclass' schema file" do
            expect {
              parent_class.enumerize_schema_file = new_schema
            }.to_not change { child_class.enumerize_schema_file }
          end

          specify "it sets the parent class' schema to the new value" do
            expect { parent_class.enumerize_schema_file = new_schema }
              .to change { parent_class.enumerize_schema_file }
              .from(old_schema).to(new_schema)
          end
        end
      end
    end
  end
end
