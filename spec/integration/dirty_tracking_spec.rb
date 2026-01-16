require 'spec_helper'

describe "Dirty Tracking" do
  let(:document) do
    Doc do
      key :name, String
      key :email, String
      key :age, Integer
      key :active, Boolean
    end
  end

  describe "tracking changes on new document" do
    it "should not have changes before setting attributes" do
      doc = document.new
      expect(doc.changed?).to be_falsey
    end

    it "should track changes when attributes are set" do
      doc = document.new
      doc.name = 'John'
      expect(doc.changed?).to be_truthy
    end

    it "should list changed attributes" do
      doc = document.new
      doc.name = 'John'
      doc.email = 'john@example.com'
      expect(doc.changed).to match_array(['name', 'email'])
    end
  end

  describe "tracking changes on persisted document" do
    before do
      @doc = document.create(name: 'Original', email: 'original@example.com', age: 25)
    end

    it "should not have changes after save" do
      expect(@doc.changed?).to be_falsey
    end

    it "should track changes after modification" do
      @doc.name = 'Modified'
      expect(@doc.changed?).to be_truthy
    end

    it "should track multiple changes" do
      @doc.name = 'New Name'
      @doc.age = 30
      expect(@doc.changed).to match_array(['name', 'age'])
    end

    it "should not track unchanged attributes" do
      @doc.name = 'New Name'
      expect(@doc.changed).to_not include('email')
    end
  end

  describe "attribute_changed? methods" do
    before do
      @doc = document.create(name: 'Original', email: 'test@example.com')
    end

    it "should return true for changed attribute" do
      @doc.name = 'Changed'
      expect(@doc.name_changed?).to be_truthy
    end

    it "should return false for unchanged attribute" do
      @doc.name = 'Changed'
      expect(@doc.email_changed?).to be_falsey
    end

    it "should return false when set to same value" do
      @doc.name = 'Original'
      expect(@doc.name_changed?).to be_falsey
    end
  end

  describe "attribute_was methods" do
    before do
      @doc = document.create(name: 'Original', age: 25)
    end

    it "should return previous value" do
      @doc.name = 'New Name'
      expect(@doc.name_was).to eq('Original')
    end

    it "should return current value if unchanged" do
      expect(@doc.name_was).to eq('Original')
    end

    it "should work with numeric types" do
      @doc.age = 30
      expect(@doc.age_was).to eq(25)
    end
  end

  describe "attribute_change methods" do
    before do
      @doc = document.create(name: 'Original', age: 25)
    end

    it "should return array of [old, new] values" do
      @doc.name = 'New Name'
      expect(@doc.name_change).to eq(['Original', 'New Name'])
    end

    it "should return nil for unchanged attribute" do
      expect(@doc.name_change).to be_nil
    end

    it "should track boolean changes" do
      @doc = document.create(name: 'Test', active: true)
      @doc.active = false
      expect(@doc.active_change).to eq([true, false])
    end
  end

  describe "changes hash" do
    before do
      @doc = document.create(name: 'Original', email: 'test@example.com', age: 25)
    end

    it "should return empty hash when no changes" do
      expect(@doc.changes).to eq({})
    end

    it "should return hash of changes" do
      @doc.name = 'New Name'
      @doc.age = 30
      expect(@doc.changes).to eq({
        'name' => ['Original', 'New Name'],
        'age' => [25, 30]
      })
    end
  end

  describe "changed_attributes hash" do
    before do
      @doc = document.create(name: 'Original', age: 25)
    end

    it "should return hash of original values" do
      @doc.name = 'New Name'
      @doc.age = 30
      expect(@doc.changed_attributes).to eq({
        'name' => 'Original',
        'age' => 25
      })
    end
  end

  describe "clearing changes" do
    before do
      @doc = document.create(name: 'Original')
    end

    it "should clear changes after save" do
      @doc.name = 'Changed'
      expect(@doc.changed?).to be_truthy

      @doc.save
      expect(@doc.changed?).to be_falsey
    end

    it "should clear changes after reload" do
      @doc.name = 'Changed'
      expect(@doc.changed?).to be_truthy

      @doc.reload
      expect(@doc.changed?).to be_falsey
      expect(@doc.name).to eq('Original')
    end
  end

  describe "previous_changes" do
    before do
      @doc = document.create(name: 'Original')
    end

    it "should be empty before first save" do
      new_doc = document.new(name: 'Test')
      expect(new_doc.previous_changes).to eq({})
    end

    it "should contain changes from last save" do
      @doc.name = 'Changed'
      @doc.save

      expect(@doc.previous_changes).to include('name')
      expect(@doc.previous_changes['name']).to eq(['Original', 'Changed'])
    end

    it "should be updated on each save" do
      @doc.name = 'First Change'
      @doc.save

      @doc.name = 'Second Change'
      @doc.save

      expect(@doc.previous_changes['name']).to eq(['First Change', 'Second Change'])
    end
  end

  describe "will_save_change_to methods" do
    before do
      @doc = document.create(name: 'Original')
    end

    it "should return true when attribute will be saved" do
      @doc.name = 'Changed'
      expect(@doc.will_save_change_to_name?).to be_truthy
    end

    it "should return false when attribute unchanged" do
      expect(@doc.will_save_change_to_name?).to be_falsey
    end
  end

  describe "saved_change_to methods" do
    before do
      @doc = document.create(name: 'Original')
      @doc.name = 'Changed'
      @doc.save
    end

    it "should return true after save with change" do
      expect(@doc.saved_change_to_name?).to be_truthy
    end

    it "should return the change values" do
      expect(@doc.saved_change_to_name).to eq(['Original', 'Changed'])
    end
  end

  describe "dirty tracking with different types" do
    it "should track array changes" do
      doc_class = Doc do
        key :tags, Array
      end

      doc = doc_class.create(tags: ['ruby'])
      doc.tags = ['ruby', 'rails']
      expect(doc.tags_changed?).to be_truthy
    end

    it "should track hash changes" do
      doc_class = Doc do
        key :metadata, Hash
      end

      doc = doc_class.create(metadata: { key: 'value' })
      doc.metadata = { key: 'new_value' }
      expect(doc.metadata_changed?).to be_truthy
    end

    it "should track date changes" do
      doc_class = Doc do
        key :birthday, Date
      end

      doc = doc_class.create(birthday: Date.new(1990, 1, 1))
      doc.birthday = Date.new(1991, 2, 2)
      expect(doc.birthday_changed?).to be_truthy
      expect(doc.birthday_was).to eq(Date.new(1990, 1, 1))
    end
  end

  describe "dirty tracking with nil values" do
    before do
      @doc = document.create(name: 'Original', email: nil)
    end

    it "should track change from nil to value" do
      @doc.email = 'new@example.com'
      expect(@doc.email_changed?).to be_truthy
      expect(@doc.email_was).to be_nil
    end

    it "should track change from value to nil" do
      @doc.name = nil
      expect(@doc.name_changed?).to be_truthy
      expect(@doc.name_was).to eq('Original')
    end

    it "should not track nil to nil" do
      @doc.email = nil
      expect(@doc.email_changed?).to be_falsey
    end
  end

  describe "reset attribute methods" do
    before do
      @doc = document.create(name: 'Original', age: 25)
    end

    it "should reset attribute to original value" do
      @doc.name = 'Changed'
      @doc.reset_name!
      expect(@doc.name).to eq('Original')
      expect(@doc.name_changed?).to be_falsey
    end

    it "should clear the change tracking" do
      @doc.name = 'Changed'
      @doc.reset_name!
      expect(@doc.changes).to_not include('name')
    end
  end

  describe "restore attribute methods" do
    before do
      @doc = document.create(name: 'Original')
    end

    it "should restore attribute to previous value" do
      @doc.name = 'Changed'
      @doc.restore_name!
      expect(@doc.name).to eq('Original')
    end
  end

  describe "partial updates integration" do
    before do
      @doc = document.create(name: 'Original', email: 'test@example.com', age: 25)
    end

    it "should only update changed fields" do
      @doc.name = 'Updated'
      @doc.save

      # The document should be updated
      found = document.find(@doc.id)
      expect(found.name).to eq('Updated')
      expect(found.email).to eq('test@example.com')
    end
  end
end
