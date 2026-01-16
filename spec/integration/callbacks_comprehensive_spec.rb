require 'spec_helper'

describe "Callbacks" do
  describe "initialize callbacks" do
    let(:document) do
      Doc do
        key :name, String
        attr_accessor :callback_log

        after_initialize :setup_defaults

        def callback_log
          @callback_log ||= []
        end

        def setup_defaults
          callback_log << :after_initialize
        end
      end
    end

    it "should run after_initialize on new" do
      doc = document.new
      expect(doc.callback_log).to include(:after_initialize)
    end

    it "should run after_initialize on find" do
      created = document.create(name: 'Test')
      found = document.find(created.id)
      expect(found.callback_log).to include(:after_initialize)
    end
  end

  describe "create callbacks" do
    let(:document) do
      Doc do
        key :name, String
        key :callback_log, Array

        before_create :log_before_create
        after_create :log_after_create

        def log_before_create
          self.callback_log ||= []
          callback_log << :before_create
        end

        def log_after_create
          callback_log << :after_create
        end
      end
    end

    it "should run before_create" do
      doc = document.create(name: 'Test')
      expect(doc.callback_log).to include(:before_create)
    end

    it "should run after_create" do
      doc = document.create(name: 'Test')
      expect(doc.callback_log).to include(:after_create)
    end

    it "should run in correct order" do
      doc = document.create(name: 'Test')
      expect(doc.callback_log.index(:before_create)).to be < doc.callback_log.index(:after_create)
    end

    it "should not run on update" do
      doc = document.create(name: 'Test')
      doc.callback_log = []
      doc.name = 'Updated'
      doc.save

      expect(doc.callback_log).to_not include(:before_create)
      expect(doc.callback_log).to_not include(:after_create)
    end
  end

  describe "update callbacks" do
    let(:document) do
      Doc do
        key :name, String
        key :callback_log, Array

        before_update :log_before_update
        after_update :log_after_update

        def log_before_update
          self.callback_log ||= []
          callback_log << :before_update
        end

        def log_after_update
          callback_log << :after_update
        end
      end
    end

    it "should run on update" do
      doc = document.create(name: 'Test')
      doc.callback_log = []
      doc.name = 'Updated'
      doc.save

      expect(doc.callback_log).to include(:before_update)
      expect(doc.callback_log).to include(:after_update)
    end

    it "should not run on create" do
      doc = document.create(name: 'Test')
      expect(doc.callback_log).to_not include(:before_update)
    end
  end

  describe "save callbacks" do
    let(:document) do
      Doc do
        key :name, String
        key :callback_log, Array

        before_save :log_before_save
        after_save :log_after_save

        def log_before_save
          self.callback_log ||= []
          callback_log << :before_save
        end

        def log_after_save
          callback_log << :after_save
        end
      end
    end

    it "should run on create" do
      doc = document.create(name: 'Test')
      expect(doc.callback_log).to include(:before_save)
      expect(doc.callback_log).to include(:after_save)
    end

    it "should run on update" do
      doc = document.create(name: 'Test')
      doc.callback_log = []
      doc.name = 'Updated'
      doc.save

      expect(doc.callback_log).to include(:before_save)
      expect(doc.callback_log).to include(:after_save)
    end
  end

  describe "destroy callbacks" do
    let(:document) do
      Doc do
        key :name, String
        attr_accessor :callback_log

        before_destroy :log_before_destroy
        after_destroy :log_after_destroy

        def callback_log
          @callback_log ||= []
        end

        def log_before_destroy
          callback_log << :before_destroy
        end

        def log_after_destroy
          callback_log << :after_destroy
        end
      end
    end

    it "should run before_destroy" do
      doc = document.create(name: 'Test')
      doc.destroy
      expect(doc.callback_log).to include(:before_destroy)
    end

    it "should run after_destroy" do
      doc = document.create(name: 'Test')
      doc.destroy
      expect(doc.callback_log).to include(:after_destroy)
    end

    it "should not run on delete" do
      doc = document.create(name: 'Test')
      doc.delete
      expect(doc.callback_log).to_not include(:before_destroy)
    end
  end

  describe "callback halting" do
    let(:document) do
      Doc do
        key :name, String
        key :block_save, Boolean

        before_save :check_block

        def check_block
          throw :abort if block_save
        end
      end
    end

    it "should halt save when throwing :abort" do
      doc = document.new(name: 'Test', block_save: true)
      expect(doc.save).to be_falsey
      expect(document.count).to eq(0)
    end

    it "should allow save when not halted" do
      doc = document.new(name: 'Test', block_save: false)
      expect(doc.save).to be_truthy
    end
  end

  describe "callback with conditions" do
    let(:document) do
      Doc do
        key :name, String
        key :skip_callback, Boolean
        attr_accessor :callback_ran

        before_save :conditional_callback, unless: :skip_callback

        def conditional_callback
          @callback_ran = true
        end
      end
    end

    it "should run callback when condition is false" do
      doc = document.new(name: 'Test', skip_callback: false)
      doc.save
      expect(doc.callback_ran).to be_truthy
    end

    it "should skip callback when condition is true" do
      doc = document.new(name: 'Test', skip_callback: true)
      doc.save
      expect(doc.callback_ran).to be_nil
    end
  end

  describe "callback with :if condition" do
    let(:document) do
      Doc do
        key :name, String
        key :run_callback, Boolean
        attr_accessor :callback_ran

        before_save :conditional_callback, if: :run_callback

        def conditional_callback
          @callback_ran = true
        end
      end
    end

    it "should run callback when :if is true" do
      doc = document.new(name: 'Test', run_callback: true)
      doc.save
      expect(doc.callback_ran).to be_truthy
    end

    it "should skip callback when :if is false" do
      doc = document.new(name: 'Test', run_callback: false)
      doc.save
      expect(doc.callback_ran).to be_nil
    end
  end

  describe "multiple callbacks" do
    let(:document) do
      Doc do
        key :name, String
        key :callback_log, Array

        before_save :first_callback
        before_save :second_callback
        before_save :third_callback

        def first_callback
          self.callback_log ||= []
          callback_log << :first
        end

        def second_callback
          callback_log << :second
        end

        def third_callback
          callback_log << :third
        end
      end
    end

    it "should run callbacks in order defined" do
      doc = document.create(name: 'Test')
      expect(doc.callback_log).to eq([:first, :second, :third])
    end
  end

  describe "callback modifying attributes" do
    let(:document) do
      Doc do
        key :name, String
        key :slug, String

        before_save :generate_slug

        def generate_slug
          self.slug = name.to_s.downcase.gsub(/\s+/, '-')
        end
      end
    end

    it "should modify attributes in callback" do
      doc = document.create(name: 'Hello World')
      expect(doc.slug).to eq('hello-world')
    end

    it "should persist modified attributes" do
      doc = document.create(name: 'Test Name')
      found = document.find(doc.id)
      expect(found.slug).to eq('test-name')
    end
  end

  describe "around callbacks" do
    let(:document) do
      Doc do
        key :name, String
        key :callback_log, Array

        around_save :around_save_callback

        def around_save_callback
          self.callback_log ||= []
          callback_log << :around_before
          yield
          callback_log << :around_after
        end
      end
    end

    it "should run around callback" do
      doc = document.create(name: 'Test')
      expect(doc.callback_log).to include(:around_before)
      expect(doc.callback_log).to include(:around_after)
    end

    it "should run in correct order" do
      doc = document.create(name: 'Test')
      expect(doc.callback_log.index(:around_before)).to be < doc.callback_log.index(:around_after)
    end
  end

  describe "callback on validation" do
    let(:document) do
      Doc do
        key :name, String, required: true
        attr_accessor :validation_callback_ran

        before_validation :validation_callback

        def validation_callback
          @validation_callback_ran = true
        end
      end
    end

    it "should run before_validation" do
      doc = document.new(name: 'Test')
      doc.valid?
      expect(doc.validation_callback_ran).to be_truthy
    end

    it "should run validation callback before validation" do
      doc = document.new
      doc.valid?
      expect(doc.validation_callback_ran).to be_truthy
    end
  end

  describe "touch callbacks" do
    let(:document) do
      Doc do
        key :name, String
        attr_accessor :touch_callback_ran

        timestamps!

        before_touch :touch_callback
        after_touch :after_touch_callback

        def touch_callback
          @touch_callback_ran = true
        end

        def after_touch_callback
          @after_touch_ran = true
        end
      end
    end

    it "should run touch callbacks" do
      doc = document.create(name: 'Test')
      doc.touch
      expect(doc.touch_callback_ran).to be_truthy
    end
  end

  describe "find callbacks" do
    let(:document) do
      Doc do
        key :name, String
        attr_accessor :find_callback_ran

        after_find :find_callback

        def find_callback
          @find_callback_ran = true
        end
      end
    end

    it "should run after_find callback" do
      created = document.create(name: 'Test')
      found = document.find(created.id)
      expect(found.find_callback_ran).to be_truthy
    end
  end

  describe "callback order across types" do
    let(:document) do
      Doc do
        key :name, String
        key :callback_log, Array

        before_validation :log_before_validation
        after_validation :log_after_validation
        before_save :log_before_save
        before_create :log_before_create
        after_create :log_after_create
        after_save :log_after_save

        def log_before_validation
          self.callback_log ||= []
          callback_log << :before_validation
        end

        def log_after_validation
          callback_log << :after_validation
        end

        def log_before_save
          callback_log << :before_save
        end

        def log_before_create
          callback_log << :before_create
        end

        def log_after_create
          callback_log << :after_create
        end

        def log_after_save
          callback_log << :after_save
        end
      end
    end

    it "should run callbacks in expected order on create" do
      doc = document.create(name: 'Test')
      expected_order = [
        :before_validation,
        :after_validation,
        :before_save,
        :before_create,
        :after_create,
        :after_save
      ]
      expect(doc.callback_log).to eq(expected_order)
    end
  end
end
