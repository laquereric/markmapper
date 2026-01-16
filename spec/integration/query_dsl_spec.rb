require 'spec_helper'

describe "Query DSL" do
  let(:document) do
    Doc do
      key :name, String
      key :age, Integer
      key :email, String
      key :active, Boolean
      key :score, Float
      key :tags, Array
      key :created_at, Time
    end
  end

  before do
    @john = document.create(name: 'John', age: 30, email: 'john@example.com', active: true, score: 85.5, tags: ['ruby', 'rails'])
    @jane = document.create(name: 'Jane', age: 25, email: 'jane@example.com', active: true, score: 92.0, tags: ['python', 'django'])
    @bob = document.create(name: 'Bob', age: 35, email: 'bob@example.com', active: false, score: 78.0, tags: ['ruby', 'sinatra'])
    @alice = document.create(name: 'Alice', age: 28, email: 'alice@example.com', active: true, score: 88.5, tags: ['javascript', 'react'])
  end

  describe ".where" do
    it "should find documents matching single condition" do
      results = document.where(name: 'John').all
      expect(results.size).to eq(1)
      expect(results.first.name).to eq('John')
    end

    it "should find documents matching multiple conditions" do
      results = document.where(active: true, age: 30).all
      expect(results.size).to eq(1)
      expect(results.first.name).to eq('John')
    end

    it "should return empty array when no matches" do
      results = document.where(name: 'NonExistent').all
      expect(results).to be_empty
    end

    it "should be chainable" do
      results = document.where(active: true).where(age: 25).all
      expect(results.size).to eq(1)
      expect(results.first.name).to eq('Jane')
    end

    it "should find documents with boolean false" do
      results = document.where(active: false).all
      expect(results.size).to eq(1)
      expect(results.first.name).to eq('Bob')
    end
  end

  describe ".filter" do
    it "should be an alias for where" do
      results = document.filter(name: 'Jane').all
      expect(results.size).to eq(1)
      expect(results.first.name).to eq('Jane')
    end
  end

  describe "comparison operators" do
    context "greater than" do
      it "should find documents with .gt" do
        results = document.where(:age.gt => 28).all
        expect(results.size).to eq(2)
        expect(results.map(&:name)).to match_array(['John', 'Bob'])
      end
    end

    context "greater than or equal" do
      it "should find documents with .gte" do
        results = document.where(:age.gte => 30).all
        expect(results.size).to eq(2)
        expect(results.map(&:name)).to match_array(['John', 'Bob'])
      end
    end

    context "less than" do
      it "should find documents with .lt" do
        results = document.where(:age.lt => 28).all
        expect(results.size).to eq(1)
        expect(results.first.name).to eq('Jane')
      end
    end

    context "less than or equal" do
      it "should find documents with .lte" do
        results = document.where(:age.lte => 28).all
        expect(results.size).to eq(2)
        expect(results.map(&:name)).to match_array(['Jane', 'Alice'])
      end
    end

    context "not equal" do
      it "should find documents with .ne" do
        results = document.where(:name.ne => 'John').all
        expect(results.size).to eq(3)
        expect(results.map(&:name)).to match_array(['Jane', 'Bob', 'Alice'])
      end
    end

    context "equality" do
      it "should find documents with .eq" do
        results = document.where(:name.eq => 'Alice').all
        expect(results.size).to eq(1)
        expect(results.first.name).to eq('Alice')
      end
    end
  end

  describe ".sort / .order" do
    it "should sort ascending by default" do
      results = document.sort(:age).all
      expect(results.map(&:name)).to eq(['Jane', 'Alice', 'John', 'Bob'])
    end

    it "should sort descending with desc symbol operator" do
      results = document.sort(:age.desc).all
      expect(results.map(&:name)).to eq(['Bob', 'John', 'Alice', 'Jane'])
    end

    it "should sort ascending with asc symbol operator" do
      results = document.sort(:name.asc).all
      expect(results.map(&:name)).to eq(['Alice', 'Bob', 'Jane', 'John'])
    end

    it "should work with .order alias" do
      results = document.order(:age).all
      expect(results.map(&:name)).to eq(['Jane', 'Alice', 'John', 'Bob'])
    end

    it "should support multiple sort fields" do
      document.create(name: 'Aaron', age: 30, email: 'aaron@example.com', active: true, score: 90.0)
      results = document.sort(:age, :name.asc).all
      names = results.map(&:name)
      expect(names.first).to eq('Jane')
    end
  end

  describe ".limit" do
    it "should limit results" do
      results = document.sort(:age).limit(2).all
      expect(results.size).to eq(2)
      expect(results.map(&:name)).to eq(['Jane', 'Alice'])
    end

    it "should be chainable with other methods" do
      results = document.where(active: true).sort(:age).limit(2).all
      expect(results.size).to eq(2)
    end
  end

  describe ".skip / .offset" do
    it "should skip results" do
      results = document.sort(:age).skip(2).all
      expect(results.size).to eq(2)
      expect(results.map(&:name)).to eq(['John', 'Bob'])
    end

    it "should work with .offset alias" do
      results = document.sort(:age).offset(1).all
      expect(results.size).to eq(3)
    end

    it "should work with limit" do
      results = document.sort(:age).skip(1).limit(2).all
      expect(results.size).to eq(2)
      expect(results.map(&:name)).to eq(['Alice', 'John'])
    end
  end

  describe ".first" do
    it "should return first document" do
      result = document.sort(:age).first
      expect(result.name).to eq('Jane')
    end

    it "should accept conditions" do
      result = document.first(name: 'Bob')
      expect(result.name).to eq('Bob')
    end

    it "should return nil when no match" do
      result = document.first(name: 'NonExistent')
      expect(result).to be_nil
    end
  end

  describe ".last" do
    it "should return last document" do
      result = document.sort(:age).last
      expect(result.name).to eq('Bob')
    end

    it "should accept conditions" do
      result = document.last(order: :age, active: true)
      expect(result.name).to eq('John')
    end
  end

  describe ".all" do
    it "should return all documents" do
      results = document.all
      expect(results.size).to eq(4)
    end

    it "should accept conditions" do
      results = document.all(active: true)
      expect(results.size).to eq(3)
    end

    it "should accept order option" do
      results = document.all(order: :age)
      expect(results.first.name).to eq('Jane')
    end
  end

  describe ".count" do
    it "should count all documents" do
      expect(document.count).to eq(4)
    end

    it "should count with conditions" do
      expect(document.count(active: true)).to eq(3)
    end

    it "should count with array condition" do
      expect(document.count(age: [25, 30])).to eq(2)
    end
  end

  describe ".exists?" do
    it "should return true when documents exist" do
      expect(document.exists?).to be_truthy
    end

    it "should return true when matching documents exist" do
      expect(document.exists?(name: 'John')).to be_truthy
    end

    it "should return false when no matching documents" do
      expect(document.exists?(name: 'NonExistent')).to be_falsey
    end
  end

  describe ".empty?" do
    it "should return false when documents exist" do
      expect(document.empty?).to be_falsey
    end

    it "should return true when no documents" do
      document.delete_all
      expect(document.empty?).to be_truthy
    end
  end

  describe ".fields / .only / .ignore" do
    it "should select specific fields with .fields" do
      results = document.fields(:name, :age).all
      results.each do |doc|
        expect(doc.name).to_not be_nil
        expect(doc.email).to be_nil
      end
    end

    it "should select specific fields with .only" do
      results = document.only(:name).all
      results.each do |doc|
        expect(doc.name).to_not be_nil
        expect(doc.age).to be_nil
      end
    end

    it "should exclude fields with .ignore" do
      results = document.ignore(:email, :tags).all
      results.each do |doc|
        expect(doc.name).to_not be_nil
        expect(doc.email).to be_nil
      end
    end
  end

  describe ".find" do
    it "should find by single id" do
      found = document.find(@john.id)
      expect(found).to eq(@john)
    end

    it "should find by multiple ids" do
      found = document.find(@john.id, @jane.id)
      expect(found).to match_array([@john, @jane])
    end

    it "should find by array of ids" do
      found = document.find([@john.id, @bob.id])
      expect(found).to match_array([@john, @bob])
    end

    it "should return nil for non-existent id" do
      found = document.find('nonexistent')
      expect(found).to be_nil
    end

    it "should return empty array for array with one element" do
      found = document.find([@john.id])
      expect(found).to eq([@john])
    end
  end

  describe ".find!" do
    it "should find by id" do
      found = document.find!(@john.id)
      expect(found).to eq(@john)
    end

    it "should raise DocumentNotFound when not found" do
      expect { document.find!('nonexistent') }.to raise_error(MarkMapper::DocumentNotFound)
    end
  end

  describe ".find_by_id" do
    it "should find by id" do
      found = document.find_by_id(@john.id)
      expect(found).to eq(@john)
    end

    it "should return nil when not found" do
      found = document.find_by_id('nonexistent')
      expect(found).to be_nil
    end
  end

  describe ".find_each" do
    it "should iterate over all documents" do
      names = []
      document.find_each { |doc| names << doc.name }
      expect(names).to match_array(['John', 'Jane', 'Bob', 'Alice'])
    end

    it "should accept conditions" do
      names = []
      document.find_each(active: true) { |doc| names << doc.name }
      expect(names).to match_array(['John', 'Jane', 'Alice'])
    end
  end

  describe "query chaining and immutability" do
    it "should not modify original query" do
      query1 = document.where(active: true)
      query2 = query1.where(age: 30)

      expect(query1.criteria_hash).to_not eq(query2.criteria_hash)
    end

    it "should allow complex chaining" do
      results = document
        .where(active: true)
        .sort(:age)
        .skip(1)
        .limit(2)
        .all

      expect(results.size).to eq(2)
    end
  end

  describe ".reverse" do
    it "should reverse sort order" do
      results = document.sort(:age).reverse.all
      expect(results.first.name).to eq('Bob')
      expect(results.last.name).to eq('Jane')
    end
  end

  describe ".paginate" do
    before do
      # Create more documents for pagination tests
      10.times do |i|
        document.create(name: "User#{i}", age: 20 + i, email: "user#{i}@example.com", active: true)
      end
    end

    it "should paginate results" do
      page1 = document.sort(:name).paginate(page: 1, per_page: 5)
      expect(page1.size).to eq(5)
      expect(page1.total_entries).to be >= 5
    end

    it "should return correct page" do
      page1 = document.sort(:age).paginate(page: 1, per_page: 3)
      page2 = document.sort(:age).paginate(page: 2, per_page: 3)

      expect(page1.first.age).to_not eq(page2.first.age)
    end

    it "should provide pagination metadata" do
      result = document.paginate(page: 1, per_page: 5)
      expect(result).to respond_to(:total_entries)
      expect(result).to respond_to(:total_pages)
      expect(result).to respond_to(:current_page)
    end
  end

  describe ".to_a" do
    it "should convert query to array" do
      results = document.where(active: true).to_a
      expect(results).to be_an(Array)
      expect(results.size).to eq(3)
    end
  end

  describe ".size" do
    it "should return count as alias" do
      expect(document.where(active: true).size).to eq(3)
    end
  end

  describe "array queries" do
    it "should find documents where field is in array" do
      results = document.where(name: ['John', 'Jane']).all
      expect(results.size).to eq(2)
      expect(results.map(&:name)).to match_array(['John', 'Jane'])
    end

    it "should find documents with age in array" do
      results = document.where(age: [25, 35]).all
      expect(results.size).to eq(2)
    end
  end
end
