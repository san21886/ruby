require 'sinatra'


#authentication source:http://ididitmyway.heroku.com/past/2011/2/22/really_simple_authentication_in_sinatra/

set :username,'admin'
set :token,'ankjoncnDhbsan'
set :password,'me'

dir=File.dirname(File.expand_path(__FILE__))+"/"+"data"
previous_page="/"

helpers do
	def delete? ; request.cookies[settings.username] == settings.token ; end
	def protected! 
		if not delete?
			#halt [ 401, 'Not Authorized, please login' ]  
			redirect '/login'
		end
       	end
end

get '/' do
	erb :fe_index
end

get '/list' do
	files=EditFile.new.get_dir_files(dir)
	@files=files.join("<br/>")
	erb :fe_index
end

get '/edit' do
	files=EditFile.new.get_dir_files(dir)
	@files=files.map{|val| fn=File.basename(val); "<a href='/edit/#{fn}'>#{val}</a>"}.join("<br/>")
	erb :fe_index
end

get '/delete' do
	previous_page="/delete"
	protected!
	files=EditFile.new.get_dir_files(dir)
	@files=files.map{|val| fn=File.basename(val); "<form method='post'><input type='checkbox' name=#{fn}>#{val}</input>"}.join("<br/>")
	@files+="<br/><button type='submit'>Submit</button></form>"
	erb :fe_index
end

post '/delete' do
	files=params.select{|key,val| val=="on"}.keys
	files.map!{|file| File.join(dir, file)}
	EditFile.new.delete_file(files)
	redirect '/'
end

get '/create' do
	erb :create_file
end

post '/create' do
	if not params["fn"] or params["fn"].chomp.strip.empty?
		@content=params["content"]
		erb :create_file
	else
		file_creation_status = EditFile.new.create_file(File.join(dir,params["fn"].chomp.strip), params["content"])
		if file_creation_status=="ok"
			redirect "/"
		else
			file_creation_status
		end
	end
end

get '/edit/*' do
	file=File.join(dir, params[:splat])
	if File.file?(file)
		@text=EditFile.new.get_file_content(file)
	end
	erb :textarea
end

post '/edit/*' do
	file=File.join(dir, params[:splat])
	text=params[:ta1]
	EditFile.new.modify_file_content(file, text)
	redirect '/'
end

get '/login' do
	erb :login
end

get '/logout' do
	response.set_cookie(settings.username, false) 
	redirect '/'
end

post '/login' do
	if params['username']==settings.username&&params['password']==settings.password
		response.set_cookie(settings.username,settings.token)
		redirect previous_page
	else
		"Username or Password incorrect"
	end
end

class EditFile
	def get_dir_files(dir)
		files=[]
		Dir::glob("#{dir}/*").each do |file|
			files.push(file)
		end
		return files
	end

	def delete_file(files)
		files.each do |file|
			if File.exists?(file)
				File.delete(file)
			end
		end
	end

	def create_file(file, content=nil)
		if File.exist?(file)
			return "#{file} already exists. Please provide another name"
		else
			if not content
				File.open(file,"w").close
			else
				File.open(file,"w") do |file|
					file << content
				end
			end
			return "ok"
		end
	end

	def modify_file_content(file, content)
		File.open(file,"w") do |f|
			f.puts content
		end
	end

	def get_file_content(file)
		lines = IO.readlines(file)
		return lines.join("\n")
	end
end
