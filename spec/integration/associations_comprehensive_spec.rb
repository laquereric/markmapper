require 'spec_helper'

describe "Associations" do
  describe "belongs_to" do
    let(:user_class) do
      Doc('User') do
        key :name, String
      end
    end

    let(:post_class) do
      user = user_class
      Doc('Post') do
        key :title, String
        key :user_id, ObjectId
        belongs_to :user, class_name: user.name
      end
    end

    it "should define association methods" do
      post = post_class.new
      expect(post).to respond_to(:user)
      expect(post).to respond_to(:user=)
    end

    it "should set and get associated document" do
      user = user_class.create(name: 'John')
      post = post_class.create(title: 'Test Post', user: user)

      expect(post.user).to eq(user)
      expect(post.user_id).to eq(user.id)
    end

    it "should load associated document from database" do
      user = user_class.create(name: 'John')
      post = post_class.create(title: 'Test Post', user: user)

      found_post = post_class.find(post.id)
      expect(found_post.user).to eq(user)
    end

    it "should allow setting by id" do
      user = user_class.create(name: 'John')
      post = post_class.new(title: 'Test Post')
      post.user_id = user.id
      post.save

      expect(post.user).to eq(user)
    end

    it "should return nil when association is not set" do
      post = post_class.create(title: 'Orphan Post')
      expect(post.user).to be_nil
    end

    it "should clear association when set to nil" do
      user = user_class.create(name: 'John')
      post = post_class.create(title: 'Test Post', user: user)

      post.user = nil
      post.save

      expect(post.reload.user).to be_nil
      expect(post.user_id).to be_nil
    end
  end

  describe "belongs_to with polymorphism" do
    let(:commentable_post) do
      Doc('CommentablePost') do
        key :title, String
      end
    end

    let(:commentable_article) do
      Doc('CommentableArticle') do
        key :headline, String
      end
    end

    let(:comment_class) do
      Doc('Comment') do
        key :body, String
        key :commentable_id, ObjectId
        key :commentable_type, String
        belongs_to :commentable, polymorphic: true
      end
    end

    it "should associate with different types" do
      post = commentable_post.create(title: 'Post Title')
      article = commentable_article.create(headline: 'Article Headline')

      post_comment = comment_class.create(body: 'Comment on post', commentable: post)
      article_comment = comment_class.create(body: 'Comment on article', commentable: article)

      expect(post_comment.commentable).to eq(post)
      expect(post_comment.commentable_type).to eq('CommentablePost')

      expect(article_comment.commentable).to eq(article)
      expect(article_comment.commentable_type).to eq('CommentableArticle')
    end

    it "should persist polymorphic association" do
      post = commentable_post.create(title: 'Post')
      comment = comment_class.create(body: 'Test', commentable: post)

      found = comment_class.find(comment.id)
      expect(found.commentable).to eq(post)
    end
  end

  describe "many association" do
    let(:author_class) do
      Doc('Author') do
        key :name, String
        many :books
      end
    end

    let(:book_class) do
      Doc('Book') do
        key :title, String
        key :author_id, ObjectId
        belongs_to :author
      end
    end

    before do
      # Wire up the association
      author_class.class_eval do
        many :books, class_name: 'Book'
      end
    end

    it "should define association methods" do
      author = author_class.new
      expect(author).to respond_to(:books)
    end

    it "should return empty array when no associations" do
      author = author_class.create(name: 'Test')
      expect(author.books).to be_empty
    end

    it "should find associated documents" do
      author = author_class.create(name: 'Author')
      book1 = book_class.create(title: 'Book 1', author: author)
      book2 = book_class.create(title: 'Book 2', author: author)

      expect(author.books).to match_array([book1, book2])
    end

    it "should build new associated document" do
      author = author_class.create(name: 'Author')
      book = author.books.build(title: 'New Book')

      expect(book.author_id).to eq(author.id)
      expect(book.new?).to be_truthy
    end

    it "should create associated document" do
      author = author_class.create(name: 'Author')
      book = author.books.create(title: 'Created Book')

      expect(book.persisted?).to be_truthy
      expect(book.author).to eq(author)
    end
  end

  describe "many with :as (polymorphic reverse)" do
    let(:taggable_document) do
      Doc('TaggableDoc') do
        key :name, String
        many :tags, as: :taggable
      end
    end

    let(:tag_class) do
      Doc('Tag') do
        key :label, String
        key :taggable_id, ObjectId
        key :taggable_type, String
        belongs_to :taggable, polymorphic: true
      end
    end

    before do
      tag = tag_class
      taggable_document.class_eval do
        many :tags, as: :taggable, class_name: tag.name
      end
    end

    it "should handle polymorphic many association" do
      doc = taggable_document.create(name: 'Test Doc')
      tag1 = tag_class.create(label: 'ruby', taggable: doc)
      tag2 = tag_class.create(label: 'rails', taggable: doc)

      expect(doc.tags).to match_array([tag1, tag2])
    end
  end

  describe "embedded documents" do
    describe "one embedded" do
      let(:person_class) do
        addr = EDoc('EmbeddedAddress') do
          key :street, String
          key :city, String
          key :zip, String
        end

        Doc('Person') do
          key :name, String
          one :address, class_name: addr.name
        end
      end

      it "should embed single document" do
        person = person_class.new(name: 'John')
        person.address = { street: '123 Main St', city: 'Boston', zip: '02101' }
        person.save

        found = person_class.find(person.id)
        expect(found.address.street).to eq('123 Main St')
        expect(found.address.city).to eq('Boston')
      end

      it "should build embedded document" do
        person = person_class.new(name: 'Jane')
        address = person.build_address(street: '456 Oak Ave', city: 'NYC')

        expect(address.street).to eq('456 Oak Ave')
        expect(person.address).to eq(address)
      end

      it "should handle nil embedded document" do
        person = person_class.create(name: 'No Address')
        expect(person.address).to be_nil
      end

      it "should update embedded document" do
        person = person_class.create(name: 'Test')
        person.address = { street: 'Old Street', city: 'Old City' }
        person.save

        person.address.street = 'New Street'
        person.save

        expect(person_class.find(person.id).address.street).to eq('New Street')
      end
    end

    describe "many embedded" do
      let(:document_with_embedded) do
        note = EDoc('Note') do
          key :content, String
          key :created_at, Time
        end

        Doc('DocumentWithNotes') do
          key :title, String
          many :notes, class_name: note.name
        end
      end

      it "should embed multiple documents" do
        doc = document_with_embedded.new(title: 'Test Doc')
        doc.notes << { content: 'Note 1' }
        doc.notes << { content: 'Note 2' }
        doc.save

        found = document_with_embedded.find(doc.id)
        expect(found.notes.size).to eq(2)
        expect(found.notes.map(&:content)).to match_array(['Note 1', 'Note 2'])
      end

      it "should build embedded document in collection" do
        doc = document_with_embedded.new(title: 'Test')
        note = doc.notes.build(content: 'Built Note')

        expect(note.content).to eq('Built Note')
        expect(doc.notes).to include(note)
      end

      it "should persist embedded collection on save" do
        doc = document_with_embedded.create(title: 'Test')
        doc.notes.build(content: 'New Note')
        doc.save

        found = document_with_embedded.find(doc.id)
        expect(found.notes.size).to eq(1)
      end
    end
  end

  describe "association extensions" do
    let(:project_class) do
      Doc('ExtProject') do
        key :name, String
        many :tasks do
          def completed
            all.select { |t| t.done? }
          end

          def pending
            all.reject { |t| t.done? }
          end
        end
      end
    end

    let(:task_class) do
      Doc('ExtTask') do
        key :name, String
        key :done, Boolean
        key :ext_project_id, ObjectId
        belongs_to :ext_project

        def done?
          done == true
        end
      end
    end

    before do
      task = task_class
      project_class.class_eval do
        many :tasks, class_name: task.name do
          def completed
            all.select { |t| t.done? }
          end
        end
      end
    end

    it "should respond to extension methods" do
      project = project_class.create(name: 'Test Project')
      expect(project.tasks).to respond_to(:completed)
    end
  end

  describe "association ordering" do
    let(:ordered_parent) do
      Doc('OrderedParent') do
        key :name, String
      end
    end

    let(:ordered_child) do
      Doc('OrderedChild') do
        key :position, Integer
        key :name, String
        key :ordered_parent_id, ObjectId
        belongs_to :ordered_parent
      end
    end

    before do
      child = ordered_child
      ordered_parent.class_eval do
        many :children, class_name: child.name, order: :position
      end
    end

    it "should return children in specified order" do
      parent = ordered_parent.create(name: 'Parent')
      child3 = ordered_child.create(name: 'Third', position: 3, ordered_parent: parent)
      child1 = ordered_child.create(name: 'First', position: 1, ordered_parent: parent)
      child2 = ordered_child.create(name: 'Second', position: 2, ordered_parent: parent)

      expect(parent.children.map(&:name)).to eq(['First', 'Second', 'Third'])
    end
  end

  describe "association limiting" do
    let(:limited_parent) do
      Doc('LimitedParent') do
        key :name, String
      end
    end

    let(:limited_child) do
      Doc('LimitedChild') do
        key :name, String
        key :limited_parent_id, ObjectId
        belongs_to :limited_parent
      end
    end

    before do
      child = limited_child
      limited_parent.class_eval do
        many :recent_children, class_name: child.name, limit: 2, order: :_id.desc
      end
    end

    it "should limit associated documents" do
      parent = limited_parent.create(name: 'Parent')
      5.times { |i| limited_child.create(name: "Child #{i}", limited_parent: parent) }

      expect(parent.recent_children.size).to eq(2)
    end
  end

  describe "dependent destruction" do
    let(:parent_with_dependent) do
      Doc('ParentWithDependent') do
        key :name, String
      end
    end

    let(:dependent_child) do
      Doc('DependentChild') do
        key :name, String
        key :parent_with_dependent_id, ObjectId
        belongs_to :parent_with_dependent
      end
    end

    before do
      child = dependent_child
      parent_with_dependent.class_eval do
        many :children, class_name: child.name, dependent: :destroy
      end
    end

    it "should destroy children when parent is destroyed" do
      parent = parent_with_dependent.create(name: 'Parent')
      child1 = dependent_child.create(name: 'Child 1', parent_with_dependent: parent)
      child2 = dependent_child.create(name: 'Child 2', parent_with_dependent: parent)

      parent.destroy

      expect(dependent_child.find(child1.id)).to be_nil
      expect(dependent_child.find(child2.id)).to be_nil
    end
  end

  describe "in_array associations" do
    let(:list_class) do
      Doc('List') do
        key :name, String
        key :item_ids, Array
      end
    end

    let(:item_class) do
      Doc('Item') do
        key :name, String
      end
    end

    before do
      item = item_class
      list_class.class_eval do
        many :items, in: :item_ids, class_name: item.name
      end
    end

    it "should store ids in array" do
      list = list_class.create(name: 'My List')
      item1 = item_class.create(name: 'Item 1')
      item2 = item_class.create(name: 'Item 2')

      list.items << item1
      list.items << item2
      list.save

      found = list_class.find(list.id)
      expect(found.item_ids).to include(item1.id, item2.id)
    end

    it "should retrieve associated documents" do
      list = list_class.create(name: 'My List')
      item1 = item_class.create(name: 'Item 1')
      item2 = item_class.create(name: 'Item 2')

      list.items << item1
      list.items << item2
      list.save

      found = list_class.find(list.id)
      expect(found.items).to match_array([item1, item2])
    end
  end
end
