require 'sinatra'


#authentication source:http://ididitmyway.heroku.com/past/2011/2/22/really_simple_authentication_in_sinatra/
set :username,'admin'
set :token,'ankjoncnDhbsan'
set :password,'admin'

dir=File.dirname(File.expand_path(__FILE__))+"/"+"data"

helpers do
	def delete? ; request.cookies[settings.username] == settings.token ; end
	def protected! 
		if not delete?
			#halt [ 401, 'Not Authorized, please login' ]  
			redirect '/login'
		end
       	end
end

get '/list' do
	files=EditFile.new.get_dir_files(dir)
	files.join("\r\n")
end

get '/create/*' do
	file=File.join(dir, params[:splat])
	EditFile.new.create_file(file)
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
end

get '/delete/*' do
	protected!
	file=File.join(dir, params[:splat])
	EditFile.new.delete_file(file)
end

get '/login' do
	erb :login
end

get '/logout' do
	response.set_cookie(settings.username, false) 
end

post '/login' do
	if params['username']==settings.username&&params['password']==settings.password
		response.set_cookie(settings.username,settings.token)
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

	def delete_file(file)
		if File.exists?(file)
			File.delete(file)
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
			return "#{file} created"
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
