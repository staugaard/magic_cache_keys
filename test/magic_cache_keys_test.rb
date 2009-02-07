require File.dirname(__FILE__) + '/test_helper'

class Comment < ActiveRecord::Base
  belongs_to :post
end

class Post < ActiveRecord::Base
  belongs_to :blog
  has_many :comments, :cache_key => true
end

class Blog < ActiveRecord::Base
  has_many :posts
  has_many :posts_orderd1, :class_name => 'Post', :order => 'title DESC'
  has_many :posts_orderd2, :class_name => 'Post', :order => 'title ASC'
  has_many :posts_conditioned, :class_name => 'Post', :conditions => {:title => 'This post has a few comments'}
end

class MagicCacheKeysTest < ActiveSupport::TestCase
  fixtures :blogs, :posts, :comments
  
  test "Base class generates a collection cache key" do
    assert_not_nil(Comment.collection_cache_key)
    assert_not_nil(Post.collection_cache_key)
  end
  
  test "has_many associations generates a cache key" do
    assert_not_nil(blogs(:a_blog).posts.cache_key)
  end
  
  test "generates different cache keys on different ordering" do
    key1 = Comment.collection_cache_key(:order => 'id DESC')
    key2 = Comment.collection_cache_key(:order => 'id ASC')
    
    assert_not_equal(key1, key2)

    key1 = blogs(:a_blog).posts_orderd1.cache_key
    key2 = blogs(:a_blog).posts_orderd2.cache_key
    
    assert_not_equal(key1, key2)
  end
  
  test "generated different cache key when conditioned" do
    key1 = Comment.collection_cache_key
    key2 = Comment.collection_cache_key(:conditions => {:body => comments(:few_comments_1).body})
    
    assert_not_equal(key1, key2)

    key1 = blogs(:a_blog).posts.cache_key
    key2 = blogs(:a_blog).posts_conditioned.cache_key
    
    assert_not_equal(key1, key2)
  end
  
  test "includes info about new records when not cached" do
    key1 = blogs(:a_blog).posts.cache_key
    blogs(:a_blog).posts.build(:title => 'new blog post')
    key2 = blogs(:a_blog).posts.cache_key
    
    assert_not_equal(key1, key2)
  end

  test "includes info about new records when cached" do
    key1 = posts(:has_two_comments).comments.cache_key
    #call again to make sure the key is cached
    key1 = posts(:has_two_comments).comments.cache_key
    
    posts(:has_two_comments).comments.build(:body => 'new comment')
    
    key2 = posts(:has_two_comments).comments.cache_key.to_s
    
    assert_not_equal(key1, key2)
  end
  
  test "caches the cache key when asked to and column is present" do
    assert_nil(posts(:has_two_comments)['comments_cache_key'])

    key1 = posts(:has_two_comments).comments.cache_key
    key2 = posts(:has_two_comments)['comments_cache_key']
    
    assert_not_nil(key1)
    assert_equal(key1, key2)
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
  
  test "updates the cache key column when the items are added to the collection" do
    key1 = posts(:has_two_comments).comments.cache_key
    key1 = posts(:has_two_comments)['comments_cache_key']
    
    assert_not_nil(key1)
    
    posts(:has_two_comments).comments.create(:body => 'new comment')
    
    key2 = posts(:has_two_comments)['comments_cache_key']
    
    assert_not_nil(key2)
    assert_not_equal(key1, key2)
  end
  
  test "updates the cache key column when the items are removed from the collection" do
    
  end
end
