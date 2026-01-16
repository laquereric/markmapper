require 'spec_helper'

describe "Validations" do
  describe "presence validation" do
    let(:document) do
      Doc do
        key :name, String
        key :email, String

        validates_presence_of :name
      end
    end

    it "should be valid with name present" do
      doc = document.new(name: 'John')
      expect(doc.valid?).to be_truthy
    end

    it "should be invalid without name" do
      doc = document.new(email: 'test@example.com')
      expect(doc.valid?).to be_falsey
    end

    it "should have error on name" do
      doc = document.new
      doc.valid?
      expect(doc.errors[:name]).to_not be_empty
    end

    it "should not save invalid document" do
      doc = document.new
      expect(doc.save).to be_falsey
    end
  end

  describe "required option on key" do
    let(:document) do
      Doc do
        key :title, String, required: true
        key :body, String
      end
    end

    it "should validate required fields" do
      doc = document.new(body: 'Some body')
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:title]).to_not be_empty
    end

    it "should be valid when required field present" do
      doc = document.new(title: 'Test Title')
      expect(doc.valid?).to be_truthy
    end
  end

  describe "length validation" do
    let(:document) do
      Doc do
        key :username, String
        key :bio, String
        key :password, String

        validates_length_of :username, minimum: 3, maximum: 20
        validates_length_of :bio, maximum: 500
        validates_length_of :password, in: 6..128
      end
    end

    it "should validate minimum length" do
      doc = document.new(username: 'ab', password: '123456')
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:username]).to_not be_empty
    end

    it "should validate maximum length" do
      doc = document.new(username: 'a' * 25, password: '123456')
      expect(doc.valid?).to be_falsey
    end

    it "should validate length range" do
      doc = document.new(username: 'valid', password: '12345') # too short
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:password]).to_not be_empty
    end

    it "should be valid within range" do
      doc = document.new(username: 'validuser', password: 'validpassword')
      expect(doc.valid?).to be_truthy
    end
  end

  describe "format validation" do
    let(:document) do
      Doc do
        key :email, String
        key :phone, String

        validates_format_of :email, with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
        validates_format_of :phone, with: /\A\d{3}-\d{3}-\d{4}\z/, allow_blank: true
      end
    end

    it "should validate email format" do
      doc = document.new(email: 'invalid-email')
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:email]).to_not be_empty
    end

    it "should accept valid email" do
      doc = document.new(email: 'valid@example.com')
      expect(doc.valid?).to be_truthy
    end

    it "should allow blank when specified" do
      doc = document.new(email: 'valid@example.com', phone: '')
      expect(doc.valid?).to be_truthy
    end

    it "should validate format when present" do
      doc = document.new(email: 'valid@example.com', phone: 'invalid')
      expect(doc.valid?).to be_falsey
    end
  end

  describe "numericality validation" do
    let(:document) do
      Doc do
        key :age, Integer
        key :price, Float
        key :quantity, Integer
        key :rating, Float

        validates_numericality_of :age, only_integer: true, greater_than_or_equal_to: 0
        validates_numericality_of :price, greater_than: 0
        validates_numericality_of :quantity, greater_than_or_equal_to: 1, less_than_or_equal_to: 100
        validates_numericality_of :rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5
      end
    end

    it "should validate integer only" do
      doc = document.new(age: 25, price: 10.0, quantity: 5, rating: 4.5)
      expect(doc.valid?).to be_truthy
    end

    it "should validate greater than" do
      doc = document.new(age: 25, price: 0, quantity: 5, rating: 3)
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:price]).to_not be_empty
    end

    it "should validate range" do
      doc = document.new(age: 25, price: 10.0, quantity: 101, rating: 3)
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:quantity]).to_not be_empty
    end

    it "should validate non-negative" do
      doc = document.new(age: -1, price: 10.0, quantity: 5, rating: 3)
      expect(doc.valid?).to be_falsey
    end
  end

  describe "inclusion validation" do
    let(:document) do
      Doc do
        key :status, String
        key :priority, Integer

        validates_inclusion_of :status, in: %w[pending active completed]
        validates_inclusion_of :priority, in: 1..5
      end
    end

    it "should validate inclusion in array" do
      doc = document.new(status: 'invalid', priority: 3)
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:status]).to_not be_empty
    end

    it "should validate inclusion in range" do
      doc = document.new(status: 'active', priority: 10)
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:priority]).to_not be_empty
    end

    it "should be valid with included values" do
      doc = document.new(status: 'active', priority: 3)
      expect(doc.valid?).to be_truthy
    end
  end

  describe "exclusion validation" do
    let(:document) do
      Doc do
        key :username, String

        validates_exclusion_of :username, in: %w[admin root superuser]
      end
    end

    it "should be invalid with excluded value" do
      doc = document.new(username: 'admin')
      expect(doc.valid?).to be_falsey
    end

    it "should be valid with non-excluded value" do
      doc = document.new(username: 'john')
      expect(doc.valid?).to be_truthy
    end
  end

  describe "uniqueness validation" do
    let(:document) do
      Doc do
        key :email, String

        validates_uniqueness_of :email
      end
    end

    it "should be valid for unique value" do
      document.create(email: 'first@example.com')
      doc = document.new(email: 'second@example.com')
      expect(doc.valid?).to be_truthy
    end

    it "should be invalid for duplicate value" do
      document.create(email: 'duplicate@example.com')
      doc = document.new(email: 'duplicate@example.com')
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:email]).to_not be_empty
    end

    it "should allow same value on update" do
      existing = document.create(email: 'existing@example.com')
      existing.email = 'existing@example.com'
      expect(existing.valid?).to be_truthy
    end
  end

  describe "uniqueness with scope" do
    let(:document) do
      Doc do
        key :name, String
        key :organization_id, ObjectId

        validates_uniqueness_of :name, scope: :organization_id
      end
    end

    it "should allow same name in different scopes" do
      doc1 = document.create(name: 'Project', organization_id: MarkLogic::ObjectId.new)
      doc2 = document.new(name: 'Project', organization_id: MarkLogic::ObjectId.new)
      expect(doc2.valid?).to be_truthy
    end

    it "should reject duplicate in same scope" do
      org_id = MarkLogic::ObjectId.new
      document.create(name: 'Project', organization_id: org_id)
      doc2 = document.new(name: 'Project', organization_id: org_id)
      expect(doc2.valid?).to be_falsey
    end
  end

  describe "custom validation" do
    let(:document) do
      Doc do
        key :start_date, Date
        key :end_date, Date

        validate :end_date_after_start_date

        def end_date_after_start_date
          return unless start_date && end_date
          if end_date < start_date
            errors.add(:end_date, 'must be after start date')
          end
        end
      end
    end

    it "should run custom validation" do
      doc = document.new(start_date: Date.today, end_date: Date.today - 1)
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:end_date]).to include('must be after start date')
    end

    it "should pass valid custom validation" do
      doc = document.new(start_date: Date.today, end_date: Date.today + 1)
      expect(doc.valid?).to be_truthy
    end
  end

  describe "conditional validation" do
    let(:document) do
      Doc do
        key :email, String
        key :notify_by_email, Boolean

        validates_presence_of :email, if: :notify_by_email
      end
    end

    it "should skip validation when condition is false" do
      doc = document.new(notify_by_email: false)
      expect(doc.valid?).to be_truthy
    end

    it "should run validation when condition is true" do
      doc = document.new(notify_by_email: true)
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:email]).to_not be_empty
    end
  end

  describe "validation with lambda condition" do
    let(:document) do
      Doc do
        key :password, String
        key :password_required, Boolean

        validates_presence_of :password, if: -> { password_required }
      end
    end

    it "should evaluate lambda condition" do
      doc = document.new(password_required: true)
      expect(doc.valid?).to be_falsey
    end

    it "should skip when lambda returns false" do
      doc = document.new(password_required: false)
      expect(doc.valid?).to be_truthy
    end
  end

  describe "validation contexts" do
    let(:document) do
      Doc do
        key :name, String
        key :terms_accepted, Boolean

        validates_presence_of :name
        validates_acceptance_of :terms_accepted, on: :create
      end
    end

    it "should validate on create context" do
      doc = document.new(name: 'Test')
      expect(doc.valid?(:create)).to be_falsey
    end

    it "should not validate create-only on update" do
      doc = document.create(name: 'Test', terms_accepted: true)
      doc.terms_accepted = false
      expect(doc.valid?(:update)).to be_truthy
    end
  end

  describe "errors" do
    let(:document) do
      Doc do
        key :name, String
        key :email, String

        validates_presence_of :name, :email
      end
    end

    it "should collect multiple errors" do
      doc = document.new
      doc.valid?
      expect(doc.errors.count).to eq(2)
    end

    it "should provide full messages" do
      doc = document.new
      doc.valid?
      expect(doc.errors.full_messages).to include("Name can't be blank")
    end

    it "should clear errors on revalidation" do
      doc = document.new
      doc.valid?
      expect(doc.errors).to_not be_empty

      doc.name = 'Test'
      doc.email = 'test@example.com'
      doc.valid?
      expect(doc.errors).to be_empty
    end
  end

  describe "save with validations" do
    let(:document) do
      Doc do
        key :name, String, required: true
      end
    end

    it "should not save invalid document" do
      doc = document.new
      expect(doc.save).to be_falsey
      expect(document.count).to eq(0)
    end

    it "should save valid document" do
      doc = document.new(name: 'Valid')
      expect(doc.save).to be_truthy
      expect(document.count).to eq(1)
    end

    it "should allow skipping validations" do
      doc = document.new
      expect(doc.save(validate: false)).to be_truthy
      expect(document.count).to eq(1)
    end
  end

  describe "validates method" do
    let(:document) do
      Doc do
        key :name, String
        key :age, Integer

        validates :name, presence: true, length: { minimum: 2, maximum: 50 }
        validates :age, numericality: { greater_than: 0 }, allow_nil: true
      end
    end

    it "should apply multiple validations" do
      doc = document.new(name: 'a')
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:name]).to_not be_empty
    end

    it "should validate all conditions" do
      doc = document.new(name: 'Valid Name', age: -1)
      expect(doc.valid?).to be_falsey
      expect(doc.errors[:age]).to_not be_empty
    end

    it "should allow nil when specified" do
      doc = document.new(name: 'Valid', age: nil)
      expect(doc.valid?).to be_truthy
    end
  end
end
