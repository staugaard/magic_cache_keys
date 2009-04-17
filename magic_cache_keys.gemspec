# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{magic_cache_keys}
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mick Staugaard", "Morten Primdahl"]
  s.date = %q{2009-04-17}
  s.description = %q{An extension of ActiveRecord adding database side generated cache keys for collections}
  s.email = %q{mick@staugaard.com}
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["VERSION.yml", "lib/magic_cache_keys.rb", "test/database.yml", "test/fixtures", "test/fixtures/blogs.yml", "test/fixtures/comments.yml", "test/fixtures/posts.yml", "test/magic_cache_keys_test.rb", "test/schema.rb", "test/test_helper.rb", "README", "LICENSE"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/staugaard/magic_cache_keys}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{An extension of ActiveRecord adding database side generated cache keys for collections}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
