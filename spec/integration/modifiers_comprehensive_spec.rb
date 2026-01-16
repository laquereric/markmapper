require 'spec_helper'

describe "Modifiers" do
  let(:document) do
    Doc do
      key :name, String
      key :count, Integer
      key :balance, Float
      key :tags, Array
      key :metadata, Hash
      key :active, Boolean
    end
  end

  before do
    @doc = document.create(
      name: 'Test',
      count: 10,
      balance: 100.0,
      tags: ['ruby', 'rails'],
      metadata: { key: 'value' },
      active: true
    )
  end

  describe "increment" do
    it "should increment integer field" do
      @doc.increment(count: 1)
      expect(@doc.reload.count).to eq(11)
    end

    it "should increment by specified amount" do
      @doc.increment(count: 5)
      expect(@doc.reload.count).to eq(15)
    end

    it "should increment float field" do
      @doc.increment(balance: 50.5)
      expect(@doc.reload.balance).to eq(150.5)
    end

    it "should increment multiple fields" do
      @doc.increment(count: 2, balance: 25.0)
      @doc.reload
      expect(@doc.count).to eq(12)
      expect(@doc.balance).to eq(125.0)
    end

    it "should handle negative increment" do
      @doc.increment(count: -3)
      expect(@doc.reload.count).to eq(7)
    end
  end

  describe "decrement" do
    it "should decrement integer field" do
      @doc.decrement(count: 1)
      expect(@doc.reload.count).to eq(9)
    end

    it "should decrement by specified amount" do
      @doc.decrement(count: 5)
      expect(@doc.reload.count).to eq(5)
    end

    it "should decrement float field" do
      @doc.decrement(balance: 30.0)
      expect(@doc.reload.balance).to eq(70.0)
    end

    it "should allow negative balance" do
      @doc.decrement(balance: 150.0)
      expect(@doc.reload.balance).to eq(-50.0)
    end
  end

  describe "set" do
    it "should set single field" do
      @doc.set(name: 'Updated')
      expect(@doc.reload.name).to eq('Updated')
    end

    it "should set multiple fields" do
      @doc.set(name: 'New Name', count: 20)
      @doc.reload
      expect(@doc.name).to eq('New Name')
      expect(@doc.count).to eq(20)
    end

    it "should set boolean field" do
      @doc.set(active: false)
      expect(@doc.reload.active).to be_falsey
    end

    it "should set array field" do
      @doc.set(tags: ['python', 'django'])
      expect(@doc.reload.tags).to eq(['python', 'django'])
    end

    it "should set hash field" do
      @doc.set(metadata: { new_key: 'new_value' })
      expect(@doc.reload.metadata).to eq({ 'new_key' => 'new_value' })
    end

    it "should set field to nil" do
      @doc.set(name: nil)
      expect(@doc.reload.name).to be_nil
    end
  end

  describe "unset" do
    it "should unset single field" do
      @doc.unset(:name)
      expect(@doc.reload.name).to be_nil
    end

    it "should unset multiple fields" do
      @doc.unset(:name, :count)
      @doc.reload
      expect(@doc.name).to be_nil
      expect(@doc.count).to be_nil
    end

    it "should unset array field" do
      @doc.unset(:tags)
      expect(@doc.reload.tags).to be_nil
    end
  end

  describe "push" do
    it "should push value to array" do
      @doc.push(tags: 'sinatra')
      expect(@doc.reload.tags).to include('sinatra')
    end

    it "should maintain existing values" do
      @doc.push(tags: 'sinatra')
      expect(@doc.reload.tags).to match_array(['ruby', 'rails', 'sinatra'])
    end

    it "should push multiple values with push_all" do
      @doc.push_all(tags: ['sinatra', 'hanami'])
      expect(@doc.reload.tags).to match_array(['ruby', 'rails', 'sinatra', 'hanami'])
    end
  end

  describe "pull" do
    it "should pull value from array" do
      @doc.pull(tags: 'rails')
      expect(@doc.reload.tags).to_not include('rails')
    end

    it "should maintain other values" do
      @doc.pull(tags: 'rails')
      expect(@doc.reload.tags).to include('ruby')
    end

    it "should pull multiple values with pull_all" do
      @doc.pull_all(tags: ['ruby', 'rails'])
      expect(@doc.reload.tags).to be_empty
    end

    it "should handle pulling non-existent value" do
      @doc.pull(tags: 'nonexistent')
      expect(@doc.reload.tags).to match_array(['ruby', 'rails'])
    end
  end

  describe "add_to_set" do
    it "should add value if not present" do
      @doc.add_to_set(tags: 'sinatra')
      expect(@doc.reload.tags).to include('sinatra')
    end

    it "should not duplicate existing value" do
      @doc.add_to_set(tags: 'ruby')
      expect(@doc.reload.tags.count('ruby')).to eq(1)
    end

    it "should add multiple values" do
      @doc.add_to_set(tags: ['sinatra', 'ruby', 'new'])
      tags = @doc.reload.tags
      expect(tags.count('ruby')).to eq(1)
      expect(tags).to include('sinatra', 'new')
    end
  end

  describe "pop" do
    it "should remove last element with 1" do
      @doc.pop(tags: 1)
      expect(@doc.reload.tags).to eq(['ruby'])
    end

    it "should remove first element with -1" do
      @doc.pop(tags: -1)
      expect(@doc.reload.tags).to eq(['rails'])
    end
  end

  describe "class-level modifiers" do
    describe ".increment" do
      it "should increment field on multiple documents" do
        doc2 = document.create(name: 'Test2', count: 5)

        document.increment({ count: 10 }, _id: @doc.id)
        expect(@doc.reload.count).to eq(20)
        expect(doc2.reload.count).to eq(5) # unchanged
      end
    end

    describe ".set" do
      it "should set field on matching documents" do
        doc2 = document.create(name: 'Test2', active: true)

        document.set({ active: false }, name: 'Test')
        expect(@doc.reload.active).to be_falsey
        expect(doc2.reload.active).to be_truthy # unchanged
      end
    end

    describe ".push" do
      it "should push to matching documents" do
        document.push({ tags: 'new_tag' }, _id: @doc.id)
        expect(@doc.reload.tags).to include('new_tag')
      end
    end

    describe ".pull" do
      it "should pull from matching documents" do
        document.pull({ tags: 'rails' }, _id: @doc.id)
        expect(@doc.reload.tags).to_not include('rails')
      end
    end
  end

  describe "modifier chaining" do
    it "should apply multiple modifications" do
      @doc.increment(count: 5)
      @doc.push(tags: 'sinatra')

      @doc.reload
      expect(@doc.count).to eq(15)
      expect(@doc.tags).to include('sinatra')
    end
  end

  describe "modifier with nil values" do
    it "should handle increment on nil field" do
      doc = document.create(name: 'NilCount')
      doc.increment(count: 5)
      expect(doc.reload.count).to eq(5)
    end

    it "should handle push on nil array" do
      doc = document.create(name: 'NilTags')
      doc.push(tags: 'first')
      expect(doc.reload.tags).to eq(['first'])
    end
  end

  describe "modifier with embedded documents" do
    let(:parent_doc) do
      note = EDoc('ModNote') do
        key :content, String
        key :likes, Integer
      end

      Doc('ModParent') do
        key :title, String
        many :notes, class_name: note.name
      end
    end

    it "should work with embedded arrays" do
      doc = parent_doc.create(title: 'Test')
      doc.notes << { content: 'Note 1', likes: 0 }
      doc.save

      # Modifiers on embedded docs work at the parent level
      expect(doc.reload.notes.size).to eq(1)
    end
  end

  describe "atomicity" do
    it "should apply modifier without loading full document" do
      id = @doc.id
      document.increment({ count: 100 }, _id: id)

      # Load fresh from database
      found = document.find(id)
      expect(found.count).to eq(110)
    end
  end

  describe "find_and_modify" do
    it "should find and update atomically" do
      result = document.find_and_modify(
        query: { _id: @doc.id },
        update: { '$set' => { name: 'Modified' } }
      )

      expect(result).to_not be_nil
      expect(@doc.reload.name).to eq('Modified')
    end

    it "should return modified document when requested" do
      result = document.find_and_modify(
        query: { _id: @doc.id },
        update: { '$inc' => { count: 5 } },
        new: true
      )

      expect(result.count).to eq(15)
    end

    it "should support upsert" do
      result = document.find_and_modify(
        query: { name: 'NonExistent' },
        update: { '$set' => { name: 'Created', count: 1 } },
        upsert: true,
        new: true
      )

      expect(result).to_not be_nil
      expect(result.name).to eq('Created')
    end
  end
end
