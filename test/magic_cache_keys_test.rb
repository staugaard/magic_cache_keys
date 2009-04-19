require File.dirname(__FILE__) + '/test_helper'

class Comment < ActiveRecord::Base
  belongs_to :post
end

class Post < ActiveRecord::Base
  belongs_to :blog
  has_many :comments, :cache_key => true
  named_scope :orderd1, {:order => 'title DESC'}
  named_scope :orderd2, {:order => 'title ASC'}
end

class Blog < ActiveRecord::Base
  has_many :posts
  has_many :posts_orderd1, :class_name => 'Post', :order => 'title DESC'
  has_many :posts_orderd2, :class_name => 'Post', :order => 'title ASC'
  has_many :posts_conditioned, :class_name => 'Post', :conditions => {:title => 'This post has a few comments'}
  has_many :posts_by_sql, :class_name => "Post", :finder_sql => 'SELECT * FROM posts WHERE blog_id = #{id}'
end

class MagicCacheKeysTest < ActiveSupport::TestCase
  fixtures :blogs, :posts, :comments
  
  test "Base class generates a collection cache key" do
    assert_not_nil(Comment.cache_key)
    assert_not_nil(Post.cache_key)
  end
  
  test "Base class generates a new cache keys when you add an item" do
    key1 = Comment.cache_key.to_s
    Comment.create(:post_id => posts(:has_many_comments).id, :body => 'yay another comment')
    key2 = Comment.cache_key.to_s
    
    assert_not_equal(key1, key2)
  end
  
  test "Base class generates a new cache keys when you remove an item" do
    key1 = Comment.cache_key.to_s
    assert_equal(Comment.delete_all(:body => 'what ever body 5000'), 1)
    key2 = Comment.cache_key.to_s
    
    assert_not_equal(key1, key2)
  end
  
  test "has_many associations generates a cache key" do
    assert_not_nil(blogs(:a_blog).posts.cache_key)
  end
  
  test "generates different cache keys on different ordering" do
    key1 = Comment.cache_key(:order => 'id DESC')
    key2 = Comment.cache_key(:order => 'id ASC')
    
    assert_not_equal(key1, key2)

    key1 = blogs(:a_blog).posts_orderd1.cache_key
    key2 = blogs(:a_blog).posts_orderd2.cache_key
    
    assert_not_equal(key1, key2)
  end
  
  test "generated different cache key when conditioned" do
    key1 = Comment.cache_key
    key2 = Comment.cache_key(:conditions => {:body => comments(:few_comments_1).body})
    
    assert_not_equal(key1, key2)

    key1 = blogs(:a_blog).posts.cache_key
    key2 = blogs(:a_blog).posts_conditioned.cache_key
    
    assert_not_equal(key1, key2)
  end
  
  test "generated the correct keys for names scopes" do
    key1 = Post.orderd1.cache_key
    key2 = Post.orderd2.cache_key
    
    assert_not_equal(key1, key2)

    key1 = Post.orderd1.cache_key
    key2 = Post.cache_key(:order => 'title DESC')
    
    assert_equal(key1, key2)

    key1 = Post.orderd2.cache_key
    key2 = Post.cache_key(:order => 'title ASC')
    
    assert_equal(key1, key2)
  end

  test "includes info about new records" do
    key1 = blogs(:a_blog).posts.cache_key
    blogs(:a_blog).posts.build(:title => 'new blog post')
    key2 = blogs(:a_blog).posts.cache_key
    
    assert_not_equal(key1, key2)
  end

  test "includes association cache key when asked to" do
    key1 = blogs(:a_blog).cache_key
    key2 = blogs(:a_blog).cache_key(:posts)
    assert_not_equal(key1, key2)
  end
  
  test "includes multiple association cache keys when asked to" do
    key1 = blogs(:a_blog).cache_key(:posts)
    key2 = blogs(:a_blog).cache_key(:posts, :posts_orderd1)
    assert_not_equal(key1, key2)
  end
  
  test "the order of the association cache keys should not matter" do
    key1 = blogs(:a_blog).cache_key(:posts_orderd1, :posts)
    key2 = blogs(:a_blog).cache_key(:posts, :posts_orderd1)
    assert_equal(key1, key2)
  end
  
  test "has_many associations with finder_sql generates a cache key" do
    key1 = blogs(:a_blog).posts_by_sql.cache_key
    assert_not_nil(key1)
    key2 = blogs(:a_blog).posts.cache_key
    assert_equal(key1, key2)
  end
end
