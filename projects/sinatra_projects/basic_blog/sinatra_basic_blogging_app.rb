#require 'sinatra'
#require 'sequel'
require 'bundler'
Bundler.require(:default)

class SqliteDBOperation
	attr_accessor :db
	def initialize(args_hash={})
		raise Exception.new("didn't provide sqlite db path") if not args_hash[:sqlite_db_path]

		begin
			@db=Sequel.connect("sqlite:#{args_hash[:sqlite_db_path]}")
			#@db=Sequel.connect("jdbc:sqlite:#{args_hash[:sqlite_db_path]}") #for jruby
		rescue Exception=>e
			$stderr.puts "could not connect to sqlite db:#{e.class}:#{e.message}"
			exit 1
		end
		create_blog_tables
	end

	def create_blog_tables
		begin
			@db.execute("create table if not exists posts(id int, title varchar, content text, category_id int, primary key(id))")
			@db.execute("create table if not exists category(id int, category_name varchar, primary key(id))")
		rescue Exception=>e
			$stderr.puts "could not create table(either post or category or both):#{e.class}:#{e.message}"
			exit 1
		end
	end

	def get_category_id(category)
		if @db[:category].filter(:category_name=>category).count==0
			@db[:category].insert(:category_name=>category)
		end
		category_id=@db[:category].filter(:category_name=>category).first[:id]
		return category_id
	end

	def add_post_info(post_hash)
		@db[:posts].insert(:category_id=>post_hash["category_id"], :title=>post_hash["title"], :content=>post_hash["post"])
	end

	def get_all_posts
		post=""
		@db[:posts].each do |row|
			title=row[:title]
			cat_id=row[:category_id]
			category=@db[:category].filter(:id=>cat_id).first[:category_name]
			content=row[:content]
			post+="Title:#{title}<br/><br/>Category:#{category}<br/><br/>#{content}<br/><br/>--------------------<br/><br/>"
		end
		return post
	end
end


sqlite_obj = SqliteDBOperation.new({:sqlite_db_path=>"/tmp/blog.db"})

get '/posts' do
	@posts=sqlite_obj.get_all_posts.to_s
	erb :display_posts
end

get '/newpost' do
	erb :new_post
end

post '/newpost' do
	category=params.key("on")
	category_id=sqlite_obj.get_category_id(category)
	params["category_id"]=category_id
	sqlite_obj.add_post_info(params)
	redirect '/posts'
end
