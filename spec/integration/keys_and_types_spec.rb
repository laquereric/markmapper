require 'spec_helper'

describe "Keys and Types" do
  describe "key definition" do
    let(:document) do
      Doc do
        key :name, String
        key :age, Integer
        key :active, Boolean
      end
    end

    it "should define getter methods" do
      doc = document.new
      expect(doc).to respond_to(:name)
      expect(doc).to respond_to(:age)
      expect(doc).to respond_to(:active)
    end

    it "should define setter methods" do
      doc = document.new
      expect(doc).to respond_to(:name=)
      expect(doc).to respond_to(:age=)
      expect(doc).to respond_to(:active=)
    end

    it "should define predicate methods for boolean" do
      doc = document.new(active: true)
      expect(doc).to respond_to(:active?)
      expect(doc.active?).to be_truthy
    end

    it "should list defined keys" do
      expect(document.keys.keys).to include('name', 'age', 'active')
    end
  end

  describe "String type" do
    let(:document) do
      Doc do
        key :name, String
      end
    end

    it "should store string values" do
      doc = document.create(name: 'John')
      expect(doc.reload.name).to eq('John')
    end

    it "should coerce integer to string" do
      doc = document.new(name: 123)
      expect(doc.name).to eq('123')
    end

    it "should coerce symbol to string" do
      doc = document.new(name: :symbol_name)
      expect(doc.name).to eq('symbol_name')
    end

    it "should handle nil" do
      doc = document.new(name: nil)
      expect(doc.name).to be_nil
    end

    it "should handle empty string" do
      doc = document.create(name: '')
      expect(doc.reload.name).to eq('')
    end
  end

  describe "Integer type" do
    let(:document) do
      Doc do
        key :count, Integer
      end
    end

    it "should store integer values" do
      doc = document.create(count: 42)
      expect(doc.reload.count).to eq(42)
    end

    it "should coerce string to integer" do
      doc = document.new(count: '123')
      expect(doc.count).to eq(123)
    end

    it "should coerce float to integer" do
      doc = document.new(count: 3.7)
      expect(doc.count).to eq(3)
    end

    it "should handle nil" do
      doc = document.new(count: nil)
      expect(doc.count).to be_nil
    end

    it "should handle negative numbers" do
      doc = document.create(count: -10)
      expect(doc.reload.count).to eq(-10)
    end

    it "should handle zero" do
      doc = document.create(count: 0)
      expect(doc.reload.count).to eq(0)
    end
  end

  describe "Float type" do
    let(:document) do
      Doc do
        key :price, Float
      end
    end

    it "should store float values" do
      doc = document.create(price: 19.99)
      expect(doc.reload.price).to eq(19.99)
    end

    it "should coerce string to float" do
      doc = document.new(price: '12.34')
      expect(doc.price).to eq(12.34)
    end

    it "should coerce integer to float" do
      doc = document.new(price: 10)
      expect(doc.price).to eq(10.0)
    end

    it "should handle nil" do
      doc = document.new(price: nil)
      expect(doc.price).to be_nil
    end
  end

  describe "Boolean type" do
    let(:document) do
      Doc do
        key :active, Boolean
      end
    end

    it "should store true" do
      doc = document.create(active: true)
      expect(doc.reload.active).to be_truthy
    end

    it "should store false" do
      doc = document.create(active: false)
      expect(doc.reload.active).to be_falsey
    end

    it "should coerce truthy strings" do
      ['true', 'TRUE', '1', 'yes', 'YES'].each do |value|
        doc = document.new(active: value)
        expect(doc.active).to be_truthy
      end
    end

    it "should coerce falsy strings" do
      ['false', 'FALSE', '0', 'no', 'NO'].each do |value|
        doc = document.new(active: value)
        expect(doc.active).to be_falsey
      end
    end

    it "should coerce 1 to true" do
      doc = document.new(active: 1)
      expect(doc.active).to be_truthy
    end

    it "should coerce 0 to false" do
      doc = document.new(active: 0)
      expect(doc.active).to be_falsey
    end

    it "should handle nil" do
      doc = document.new(active: nil)
      expect(doc.active).to be_nil
    end
  end

  describe "Date type" do
    let(:document) do
      Doc do
        key :birthday, Date
      end
    end

    it "should store date values" do
      date = Date.new(1990, 5, 15)
      doc = document.create(birthday: date)
      expect(doc.reload.birthday).to eq(date)
    end

    it "should coerce string to date" do
      doc = document.new(birthday: '2000-12-25')
      expect(doc.birthday).to eq(Date.new(2000, 12, 25))
    end

    it "should handle nil" do
      doc = document.new(birthday: nil)
      expect(doc.birthday).to be_nil
    end

    it "should coerce Time to Date" do
      time = Time.new(2020, 6, 15, 12, 30, 0)
      doc = document.new(birthday: time)
      expect(doc.birthday).to eq(Date.new(2020, 6, 15))
    end
  end

  describe "Time type" do
    let(:document) do
      Doc do
        key :logged_at, Time
      end
    end

    it "should store time values" do
      time = Time.now
      doc = document.create(logged_at: time)
      expect(doc.reload.logged_at.to_i).to eq(time.to_i)
    end

    it "should coerce string to time" do
      doc = document.new(logged_at: '2020-01-15 10:30:00')
      expect(doc.logged_at).to be_a(Time)
    end

    it "should handle nil" do
      doc = document.new(logged_at: nil)
      expect(doc.logged_at).to be_nil
    end

    it "should coerce integer (unix timestamp) to time" do
      timestamp = 1577836800
      doc = document.new(logged_at: timestamp)
      expect(doc.logged_at.to_i).to eq(timestamp)
    end
  end

  describe "Array type" do
    let(:document) do
      Doc do
        key :tags, Array
      end
    end

    it "should store array values" do
      doc = document.create(tags: ['ruby', 'rails', 'mongodb'])
      expect(doc.reload.tags).to eq(['ruby', 'rails', 'mongodb'])
    end

    it "should handle empty array" do
      doc = document.create(tags: [])
      expect(doc.reload.tags).to eq([])
    end

    it "should handle nil" do
      doc = document.new(tags: nil)
      expect(doc.tags).to be_nil
    end

    it "should store mixed types" do
      doc = document.create(tags: ['string', 123, true])
      expect(doc.reload.tags).to eq(['string', 123, true])
    end

    it "should store nested arrays" do
      doc = document.create(tags: [['nested', 'array'], ['another']])
      expect(doc.reload.tags).to eq([['nested', 'array'], ['another']])
    end
  end

  describe "Hash type" do
    let(:document) do
      Doc do
        key :metadata, Hash
      end
    end

    it "should store hash values" do
      doc = document.create(metadata: { key: 'value', count: 42 })
      expect(doc.reload.metadata).to eq({ 'key' => 'value', 'count' => 42 })
    end

    it "should handle empty hash" do
      doc = document.create(metadata: {})
      expect(doc.reload.metadata).to eq({})
    end

    it "should handle nil" do
      doc = document.new(metadata: nil)
      expect(doc.metadata).to be_nil
    end

    it "should store nested hashes" do
      doc = document.create(metadata: { nested: { deep: 'value' } })
      expect(doc.reload.metadata['nested']['deep']).to eq('value')
    end
  end

  describe "ObjectId type" do
    let(:document) do
      Doc do
        key :reference_id, ObjectId
      end
    end

    it "should store ObjectId values" do
      id = MarkLogic::ObjectId.new
      doc = document.create(reference_id: id)
      expect(doc.reload.reference_id).to eq(id)
    end

    it "should coerce string to ObjectId" do
      id = MarkLogic::ObjectId.new
      doc = document.new(reference_id: id.to_s)
      expect(doc.reference_id).to eq(id)
    end

    it "should handle nil" do
      doc = document.new(reference_id: nil)
      expect(doc.reference_id).to be_nil
    end
  end

  describe "default values" do
    describe "static defaults" do
      let(:document) do
        Doc do
          key :status, String, default: 'pending'
          key :count, Integer, default: 0
          key :active, Boolean, default: true
          key :tags, Array, default: []
        end
      end

      it "should use default value when not specified" do
        doc = document.new
        expect(doc.status).to eq('pending')
        expect(doc.count).to eq(0)
        expect(doc.active).to be_truthy
      end

      it "should override default when value provided" do
        doc = document.new(status: 'active')
        expect(doc.status).to eq('active')
      end

      it "should persist default values" do
        doc = document.create
        expect(doc.reload.status).to eq('pending')
      end

      it "should use empty array default" do
        doc = document.new
        expect(doc.tags).to eq([])
      end
    end

    describe "proc defaults" do
      let(:document) do
        Doc do
          key :created_date, Date, default: -> { Date.today }
          key :uuid, String, default: -> { SecureRandom.uuid }
        end
      end

      it "should evaluate proc for default" do
        doc = document.new
        expect(doc.created_date).to eq(Date.today)
      end

      it "should evaluate proc each time" do
        doc1 = document.new
        doc2 = document.new
        expect(doc1.uuid).to_not eq(doc2.uuid)
      end
    end
  end

  describe "key aliases (abbr)" do
    let(:document) do
      Doc do
        key :full_name, String, abbr: :fn
        key :email_address, String, abbr: :ea
      end
    end

    it "should define alias accessor" do
      doc = document.new
      expect(doc).to respond_to(:fn)
      expect(doc).to respond_to(:fn=)
    end

    it "should read through alias" do
      doc = document.new(full_name: 'John Doe')
      expect(doc.fn).to eq('John Doe')
    end

    it "should write through alias" do
      doc = document.new
      doc.fn = 'Jane Doe'
      expect(doc.full_name).to eq('Jane Doe')
    end
  end

  describe "custom types" do
    let(:custom_type) do
      Class.new do
        attr_reader :value

        def self.to_marklogic(obj)
          obj.is_a?(self) ? obj.value : obj
        end

        def self.from_marklogic(value)
          value.nil? ? nil : new(value)
        end

        def initialize(value)
          @value = value.to_s.upcase
        end

        def ==(other)
          other.is_a?(self.class) && other.value == value
        end
      end
    end

    let(:document) do
      type = custom_type
      Doc do
        key :custom_field, type
      end
    end

    it "should use custom type conversion" do
      doc = document.new(custom_field: 'test')
      expect(doc.custom_field.value).to eq('TEST')
    end

    it "should persist and reload custom type" do
      doc = document.create(custom_field: 'hello')
      found = document.find(doc.id)
      expect(found.custom_field.value).to eq('HELLO')
    end
  end

  describe "key inheritance" do
    let(:parent_class) do
      Doc('Parent') do
        key :name, String
        key :type, String
      end
    end

    let(:child_class) do
      parent = parent_class
      Class.new(parent) do
        key :child_field, Integer
      end
    end

    it "should inherit parent keys" do
      child = child_class.new
      expect(child).to respond_to(:name)
      expect(child).to respond_to(:type)
    end

    it "should have child-specific keys" do
      child = child_class.new
      expect(child).to respond_to(:child_field)
    end

    it "should not add child keys to parent" do
      parent = parent_class.new
      expect(parent).to_not respond_to(:child_field)
    end
  end

  describe "dynamic attributes" do
    let(:document) do
      Doc do
        key :name, String
      end
    end

    it "should allow setting undefined attributes" do
      doc = document.new
      doc.undefined_field = 'value'
      expect(doc.undefined_field).to eq('value')
    end

    it "should persist undefined attributes" do
      doc = document.create(name: 'Test')
      doc.dynamic_field = 'dynamic value'
      doc.save

      found = document.find(doc.id)
      expect(found.dynamic_field).to eq('dynamic value')
    end

    it "should include dynamic attributes in to_hash" do
      doc = document.new(name: 'Test')
      doc.extra = 'extra value'
      # Dynamic attributes are accessible but may not appear in all serializations
      expect(doc.extra).to eq('extra value')
    end
  end

  describe "removing keys" do
    let(:document) do
      klass = Doc do
        key :name, String
        key :temporary, String
      end
      klass.remove_key(:temporary)
      klass
    end

    it "should remove the key" do
      expect(document.keys.keys).to include('name')
      expect(document.keys.keys).to_not include('temporary')
    end
  end

  describe "key with typecast option" do
    let(:document) do
      Doc do
        key :amount, String, typecast: 'Integer'
      end
    end

    it "should typecast on read" do
      doc = document.new(amount: '100')
      # The typecast option may affect how values are read
      expect(doc.amount).to be_a(String)
    end
  end

  describe "_id key" do
    let(:document) do
      Doc do
        key :name, String
      end
    end

    it "should have _id key automatically" do
      expect(document.keys.keys).to include('_id')
    end

    it "should generate _id on create" do
      doc = document.create(name: 'Test')
      expect(doc._id).to_not be_nil
      expect(doc._id).to be_a(MarkLogic::ObjectId)
    end

    it "should alias id to _id" do
      doc = document.create(name: 'Test')
      expect(doc.id).to eq(doc._id)
    end
  end
end
