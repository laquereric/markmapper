require 'spec_helper'

describe "Connection" do
  describe "MarkMapper module" do
    it "should have a connection" do
      expect(MarkMapper.connection).to_not be_nil
    end

    it "should return true for connection?" do
      expect(MarkMapper.connection?).to be_truthy
    end

    it "should have an application" do
      expect(MarkMapper.application).to_not be_nil
    end

    it "should have a logger" do
      expect(MarkMapper.logger).to_not be_nil
    end
  end

  describe "connection configuration" do
    it "should allow setting connection", :without_connection do
      # This test runs with connection set to nil via the around hook
      expect(MarkMapper.connection).to be_nil
    end

    it "should allow setting application" do
      old_app = MarkMapper.application
      expect(old_app).to_not be_nil
      MarkMapper.application = old_app
      expect(MarkMapper.application).to eq(old_app)
    end
  end

  describe "database operations" do
    let(:document) do
      Doc do
        key :name, String
      end
    end

    it "should have access to collection" do
      expect(document.collection).to_not be_nil
    end

    it "should have access to database" do
      expect(document.database).to_not be_nil
    end

    it "should use correct collection name" do
      expect(document.collection_name).to eq('classes')
    end

    context "with custom collection name" do
      let(:custom_doc) do
        Doc do
          set_collection_name 'custom_collection'
          key :value, String
        end
      end

      it "should use the custom collection name" do
        expect(custom_doc.collection_name).to eq('custom_collection')
      end
    end
  end

  describe "connection to MarkLogic" do
    it "should be able to create and retrieve documents" do
      doc_class = Doc do
        key :test_field, String
      end

      doc = doc_class.create(test_field: 'connection_test')
      expect(doc.persisted?).to be_truthy

      found = doc_class.find(doc.id)
      expect(found).to_not be_nil
      expect(found.test_field).to eq('connection_test')
    end

    it "should handle multiple collections" do
      first_class = Doc('FirstClass') do
        key :name, String
      end

      second_class = Doc('SecondClass') do
        key :title, String
      end

      first_class.create(name: 'first')
      second_class.create(title: 'second')

      expect(first_class.count).to eq(1)
      expect(second_class.count).to eq(1)
    end
  end
end
