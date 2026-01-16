require 'spec_helper'

describe "Scopes" do
  let(:document) do
    Doc do
      key :name, String
      key :status, String
      key :priority, Integer
      key :active, Boolean
      key :created_at, Time

      scope :active, where(active: true)
      scope :inactive, where(active: false)
      scope :high_priority, where(:priority.gte => 8)
      scope :by_status, ->(status) { where(status: status) }
      scope :recent, -> { where(:created_at.gte => 1.day.ago) }
      scope :ordered_by_priority, -> { sort(:priority.desc) }
    end
  end

  before do
    @active1 = document.create(name: 'Active 1', status: 'published', priority: 9, active: true, created_at: Time.now)
    @active2 = document.create(name: 'Active 2', status: 'draft', priority: 5, active: true, created_at: Time.now)
    @inactive1 = document.create(name: 'Inactive 1', status: 'published', priority: 3, active: false, created_at: 2.days.ago)
    @high_priority = document.create(name: 'High Priority', status: 'draft', priority: 10, active: true, created_at: Time.now)
  end

  describe "basic scopes" do
    it "should filter with simple scope" do
      results = document.active.all
      expect(results.size).to eq(3)
      expect(results).to_not include(@inactive1)
    end

    it "should return correct documents with inactive scope" do
      results = document.inactive.all
      expect(results.size).to eq(1)
      expect(results.first).to eq(@inactive1)
    end

    it "should work with comparison operators" do
      results = document.high_priority.all
      expect(results.size).to eq(2)
      expect(results).to include(@active1, @high_priority)
    end
  end

  describe "scopes with parameters" do
    it "should accept parameters" do
      results = document.by_status('published').all
      expect(results.size).to eq(2)
      expect(results.map(&:status).uniq).to eq(['published'])
    end

    it "should work with different parameter values" do
      drafts = document.by_status('draft').all
      expect(drafts.size).to eq(2)

      published = document.by_status('published').all
      expect(published.size).to eq(2)
    end
  end

  describe "scope chaining" do
    it "should chain multiple scopes" do
      results = document.active.high_priority.all
      expect(results.size).to eq(2)
      expect(results).to all(satisfy { |d| d.active && d.priority >= 8 })
    end

    it "should chain scope with where" do
      results = document.active.where(status: 'published').all
      expect(results.size).to eq(1)
      expect(results.first).to eq(@active1)
    end

    it "should chain scope with sort" do
      results = document.active.sort(:priority.desc).all
      expect(results.first.priority).to eq(10)
    end

    it "should chain scope with limit" do
      results = document.active.sort(:priority.desc).limit(2).all
      expect(results.size).to eq(2)
    end

    it "should chain multiple parameterized scopes" do
      results = document.by_status('draft').high_priority.all
      expect(results.size).to eq(1)
      expect(results.first).to eq(@high_priority)
    end
  end

  describe "scopes with sorting" do
    it "should apply sort in scope" do
      results = document.ordered_by_priority.all
      priorities = results.map(&:priority)
      expect(priorities).to eq(priorities.sort.reverse)
    end

    it "should chain sorting scope with filters" do
      results = document.active.ordered_by_priority.all
      expect(results.first).to eq(@high_priority)
    end
  end

  describe "scopes with time-based queries" do
    it "should filter by time" do
      results = document.recent.all
      expect(results).to_not include(@inactive1)
    end
  end

  describe "default scope" do
    let(:document_with_default) do
      Doc do
        key :name, String
        key :deleted, Boolean

        default_scope where(deleted: false)
      end
    end

    before do
      document_with_default.create(name: 'Active', deleted: false)
      document_with_default.create(name: 'Deleted', deleted: true)
    end

    it "should apply default scope automatically" do
      results = document_with_default.all
      expect(results.size).to eq(1)
      expect(results.first.name).to eq('Active')
    end

    it "should allow unscoping" do
      results = document_with_default.unscoped.all
      expect(results.size).to eq(2)
    end
  end

  describe "scope returning query object" do
    it "should return chainable query" do
      query = document.active
      expect(query).to respond_to(:where)
      expect(query).to respond_to(:sort)
      expect(query).to respond_to(:limit)
    end

    it "should allow further refinement" do
      query = document.active
      results = query.where(:priority.gt => 5).all
      expect(results.size).to eq(2)
    end
  end

  describe "scope with count" do
    it "should count scoped results" do
      expect(document.active.count).to eq(3)
    end

    it "should count chained scopes" do
      expect(document.active.high_priority.count).to eq(2)
    end
  end

  describe "scope with first and last" do
    it "should return first from scope" do
      result = document.active.sort(:name).first
      expect(result.active).to be_truthy
    end

    it "should return last from scope" do
      result = document.active.sort(:priority).last
      expect(result).to eq(@high_priority)
    end
  end

  describe "scope with exists?" do
    it "should check existence in scope" do
      expect(document.active.exists?).to be_truthy
    end

    it "should return false for empty scope" do
      expect(document.where(name: 'NonExistent').exists?).to be_falsey
    end
  end

  describe "class method as scope" do
    let(:document_with_methods) do
      Doc do
        key :name, String
        key :score, Integer

        def self.top_scorers(limit = 5)
          sort(:score.desc).limit(limit)
        end

        def self.by_name_pattern(pattern)
          where(:name => /#{pattern}/i)
        end
      end
    end

    before do
      document_with_methods.create(name: 'Alice', score: 100)
      document_with_methods.create(name: 'Bob', score: 85)
      document_with_methods.create(name: 'Charlie', score: 95)
    end

    it "should work as scope with parameters" do
      results = document_with_methods.top_scorers(2).all
      expect(results.size).to eq(2)
      expect(results.first.score).to eq(100)
    end
  end

  describe "dynamic querying integration" do
    it "should chain scope with dynamic finder" do
      result = document.active.find_by_status('published')
      expect(result).to_not be_nil
      expect(result.active).to be_truthy
      expect(result.status).to eq('published')
    end
  end

  describe "scope immutability" do
    it "should not modify original scope" do
      original = document.active
      modified = original.where(priority: 10)

      expect(original.criteria_hash).to_not eq(modified.criteria_hash)
    end

    it "should create new query on each call" do
      scope1 = document.active
      scope2 = document.active
      expect(scope1).to_not equal(scope2)
    end
  end

  describe "scope with associations" do
    let(:parent_class) do
      Doc('ScopedParent') do
        key :name, String
      end
    end

    let(:child_class) do
      parent = parent_class
      Doc('ScopedChild') do
        key :name, String
        key :active, Boolean
        key :scoped_parent_id, ObjectId

        belongs_to :scoped_parent

        scope :active, where(active: true)
      end
    end

    before do
      parent = parent_class
      child = child_class
      parent.class_eval do
        many :children, class_name: child.name do
          def active
            where(active: true)
          end
        end
      end
    end

    it "should work with association proxy" do
      parent = parent_class.create(name: 'Parent')
      child_class.create(name: 'Active Child', active: true, scoped_parent: parent)
      child_class.create(name: 'Inactive Child', active: false, scoped_parent: parent)

      active_children = parent.children.active.all
      expect(active_children.size).to eq(1)
      expect(active_children.first.name).to eq('Active Child')
    end
  end

  describe "scope definition edge cases" do
    it "should handle scope with empty conditions" do
      doc_class = Doc do
        key :name, String
        scope :all_docs, -> { where({}) }
      end

      doc_class.create(name: 'Test')
      expect(doc_class.all_docs.count).to eq(1)
    end

    it "should handle scope that returns nil criteria" do
      doc_class = Doc do
        key :name, String
        scope :everything, -> { where(nil) }
      end

      doc_class.create(name: 'Test')
      # Should handle gracefully
      expect { doc_class.everything.all }.to_not raise_error
    end
  end
end
