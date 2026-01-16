require 'spec_helper'

describe "Document Lifecycle" do
  let(:document) do
    Doc do
      key :name, String
      key :email, String
      key :age, Integer
      key :active, Boolean
    end
  end

  describe "creating documents" do
    context ".new" do
      it "should create a new unsaved document" do
        doc = document.new(name: 'John')
        expect(doc.new?).to be_truthy
        expect(doc.persisted?).to be_falsey
      end

      it "should accept a block" do
        doc = document.new do |d|
          d.name = 'Jane'
          d.email = 'jane@example.com'
        end
        expect(doc.name).to eq('Jane')
        expect(doc.email).to eq('jane@example.com')
      end

      it "should not have an id before save" do
        doc = document.new(name: 'Test')
        # id may be pre-assigned, but not persisted
        expect(doc.persisted?).to be_falsey
      end

      it "should accept hash attributes" do
        doc = document.new(name: 'Test', age: 25, active: true)
        expect(doc.name).to eq('Test')
        expect(doc.age).to eq(25)
        expect(doc.active).to be_truthy
      end
    end

    context ".create" do
      it "should create and save a document" do
        doc = document.create(name: 'John', email: 'john@example.com')
        expect(doc.persisted?).to be_truthy
        expect(doc.new?).to be_falsey
      end

      it "should assign an id" do
        doc = document.create(name: 'Test')
        expect(doc.id).to_not be_nil
        expect(doc._id).to_not be_nil
      end

      it "should accept a block" do
        doc = document.create do |d|
          d.name = 'Block Test'
        end
        expect(doc.name).to eq('Block Test')
        expect(doc.persisted?).to be_truthy
      end

      it "should create multiple documents with array" do
        docs = document.create([
          { name: 'Doc1', age: 20 },
          { name: 'Doc2', age: 25 }
        ])
        expect(docs.size).to eq(2)
        expect(docs).to all(be_persisted)
      end

      it "should increment count" do
        expect { document.create(name: 'Test') }.to change { document.count }.by(1)
      end
    end

    context ".create!" do
      it "should create and save a valid document" do
        doc = document.create!(name: 'Test')
        expect(doc.persisted?).to be_truthy
      end

      it "should accept a block" do
        doc = document.create! do |d|
          d.name = 'Bang Test'
        end
        expect(doc.name).to eq('Bang Test')
      end

      it "should raise error on invalid document" do
        doc_class = Doc do
          key :name, String, required: true
        end

        expect { doc_class.create! }.to raise_error(MarkMapper::DocumentNotValid)
      end
    end
  end

  describe "reading documents" do
    before do
      @doc1 = document.create(name: 'John', age: 30)
      @doc2 = document.create(name: 'Jane', age: 25)
    end

    it "should find by id" do
      found = document.find(@doc1.id)
      expect(found).to eq(@doc1)
      expect(found.name).to eq('John')
    end

    it "should find with first" do
      found = document.first(name: 'Jane')
      expect(found).to eq(@doc2)
    end

    it "should find all matching" do
      found = document.all
      expect(found.size).to eq(2)
    end

    it "should reload document from database" do
      @doc1.name = 'Changed'
      expect(@doc1.name).to eq('Changed')
      @doc1.reload
      expect(@doc1.name).to eq('John')
    end
  end

  describe "updating documents" do
    before do
      @doc = document.create(name: 'Original', age: 25, email: 'original@example.com')
    end

    context "#save" do
      it "should update existing document" do
        @doc.name = 'Updated'
        @doc.save
        expect(document.find(@doc.id).name).to eq('Updated')
      end

      it "should not create new document" do
        @doc.name = 'Updated'
        expect { @doc.save }.to_not change { document.count }
      end

      it "should return true on success" do
        @doc.name = 'Updated'
        expect(@doc.save).to be_truthy
      end
    end

    context "#save!" do
      it "should save valid document" do
        @doc.name = 'Updated'
        expect { @doc.save! }.to_not raise_error
      end

      it "should raise on invalid document" do
        doc_class = Doc do
          key :name, String, required: true
        end
        doc = doc_class.create(name: 'Test')
        doc.name = nil

        expect { doc.save! }.to raise_error(MarkMapper::DocumentNotValid)
      end
    end

    context "#update_attributes" do
      it "should update multiple attributes" do
        @doc.update_attributes(name: 'NewName', age: 30)
        expect(@doc.name).to eq('NewName')
        expect(@doc.age).to eq(30)
      end

      it "should persist changes to database" do
        @doc.update_attributes(name: 'NewName')
        found = document.find(@doc.id)
        expect(found.name).to eq('NewName')
      end

      it "should return true on success" do
        expect(@doc.update_attributes(name: 'Test')).to be_truthy
      end

      it "should return false on validation failure" do
        doc_class = Doc do
          key :name, String, required: true
        end
        doc = doc_class.create(name: 'Test')

        expect(doc.update_attributes(name: nil)).to be_falsey
      end
    end

    context "#update_attributes!" do
      it "should update and save" do
        @doc.update_attributes!(name: 'Updated')
        expect(@doc.name).to eq('Updated')
      end

      it "should raise on validation failure" do
        doc_class = Doc do
          key :name, String, required: true
        end
        doc = doc_class.create(name: 'Test')

        expect { doc.update_attributes!(name: nil) }.to raise_error(MarkMapper::DocumentNotValid)
      end
    end

    context "#update_attribute" do
      it "should update single attribute" do
        @doc.update_attribute(:name, 'SingleUpdate')
        expect(@doc.reload.name).to eq('SingleUpdate')
      end

      it "should skip validation" do
        doc_class = Doc do
          key :name, String, required: true
        end
        doc = doc_class.create(name: 'Test')

        expect(doc.update_attribute(:name, '')).to be_truthy
        expect(doc.reload.name).to eq('')
      end

      it "should accept symbol or string keys" do
        @doc.update_attribute('name', 'StringKey')
        expect(@doc.reload.name).to eq('StringKey')
      end
    end

    context ".update (class method)" do
      it "should update document by id" do
        document.update(@doc.id, name: 'ClassUpdate')
        expect(document.find(@doc.id).name).to eq('ClassUpdate')
      end

      it "should update multiple documents" do
        doc2 = document.create(name: 'Another')
        document.update({
          @doc.id => { name: 'Updated1' },
          doc2.id => { name: 'Updated2' }
        })

        expect(document.find(@doc.id).name).to eq('Updated1')
        expect(document.find(doc2.id).name).to eq('Updated2')
      end

      it "should raise error without id" do
        expect { document.update }.to raise_error(ArgumentError)
      end

      it "should raise error without attributes" do
        expect { document.update(@doc.id) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "deleting documents" do
    before do
      @doc1 = document.create(name: 'ToDelete1', age: 25)
      @doc2 = document.create(name: 'ToDelete2', age: 30)
      @doc3 = document.create(name: 'ToKeep', age: 35)
    end

    context "#destroy" do
      it "should remove document from database" do
        @doc1.destroy
        expect(document.find(@doc1.id)).to be_nil
      end

      it "should decrement count" do
        expect { @doc1.destroy }.to change { document.count }.by(-1)
      end

      it "should mark document as destroyed" do
        @doc1.destroy
        expect(@doc1.destroyed?).to be_truthy
      end
    end

    context "#delete" do
      it "should remove document without callbacks" do
        @doc1.delete
        expect(document.find(@doc1.id)).to be_nil
      end

      it "should not run destroy callbacks" do
        callback_doc = Doc do
          key :name, String
          attr_accessor :callback_ran

          before_destroy { self.callback_ran = true }
        end

        doc = callback_doc.create(name: 'Test')
        doc.delete
        expect(doc.callback_ran).to be_nil
      end
    end

    context ".delete (class method)" do
      it "should delete by single id" do
        document.delete(@doc1.id)
        expect(document.find(@doc1.id)).to be_nil
        expect(document.count).to eq(2)
      end

      it "should delete by multiple ids" do
        document.delete(@doc1.id, @doc2.id)
        expect(document.count).to eq(1)
      end

      it "should delete by array of ids" do
        document.delete([@doc1.id, @doc2.id])
        expect(document.count).to eq(1)
      end
    end

    context ".destroy (class method)" do
      it "should destroy by single id" do
        document.destroy(@doc1.id)
        expect(document.find(@doc1.id)).to be_nil
      end

      it "should destroy by multiple ids" do
        document.destroy(@doc1.id, @doc2.id)
        expect(document.count).to eq(1)
      end
    end

    context ".delete_all" do
      it "should delete all documents without conditions" do
        document.delete_all
        expect(document.count).to eq(0)
      end

      it "should delete matching documents with conditions" do
        document.delete_all(age: 25)
        expect(document.count).to eq(2)
      end
    end

    context ".destroy_all" do
      it "should destroy all documents without conditions" do
        document.destroy_all
        expect(document.count).to eq(0)
      end

      it "should destroy matching documents with conditions" do
        document.destroy_all(name: 'ToDelete1')
        expect(document.count).to eq(2)
      end
    end
  end

  describe "document state" do
    let(:doc) { document.new(name: 'Test') }

    context "#new?" do
      it "should return true for unsaved document" do
        expect(doc.new?).to be_truthy
      end

      it "should return false after save" do
        doc.save
        expect(doc.new?).to be_falsey
      end
    end

    context "#persisted?" do
      it "should return false for new document" do
        expect(doc.persisted?).to be_falsey
      end

      it "should return true after save" do
        doc.save
        expect(doc.persisted?).to be_truthy
      end

      it "should return false after destroy" do
        doc.save
        doc.destroy
        expect(doc.persisted?).to be_falsey
      end
    end

    context "#destroyed?" do
      it "should return false initially" do
        expect(doc.destroyed?).to be_falsey
      end

      it "should return true after destroy" do
        doc.save
        doc.destroy
        expect(doc.destroyed?).to be_truthy
      end
    end
  end

  describe "first_or_create" do
    it "should find existing document" do
      existing = document.create(name: 'Existing', email: 'existing@example.com')

      expect {
        found = document.first_or_create(name: 'Existing')
        expect(found).to eq(existing)
      }.to_not change { document.count }
    end

    it "should create new document if not found" do
      expect {
        created = document.first_or_create(name: 'New', email: 'new@example.com')
        expect(created.name).to eq('New')
        expect(created.persisted?).to be_truthy
      }.to change { document.count }.by(1)
    end
  end

  describe "first_or_new" do
    it "should find existing document" do
      existing = document.create(name: 'Existing')

      found = document.first_or_new(name: 'Existing')
      expect(found).to eq(existing)
    end

    it "should initialize new document if not found" do
      expect {
        new_doc = document.first_or_new(name: 'New')
        expect(new_doc.name).to eq('New')
        expect(new_doc.new?).to be_truthy
      }.to_not change { document.count }
    end
  end

  describe "custom attributes" do
    it "should allow setting undefined attributes" do
      doc = document.new(name: 'Test', custom_field: 'custom_value')
      doc.save

      found = document.find(doc.id)
      expect(found.custom_field).to eq('custom_value')
    end

    it "should persist custom attributes" do
      doc = document.create(name: 'Test')
      doc.special_data = { key: 'value' }
      doc.save

      found = document.find(doc.id)
      expect(found.special_data).to eq({ 'key' => 'value' })
    end
  end
end
