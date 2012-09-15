require 'net/ftp'
require 'optparse'
require 'fileutils'

class FTPOperationsParser
	
	def self.validate(options)
		if not options[:userid] or not options[:password]
			$stderr.puts "must provide options userid and password"
			return false
		end
		return true
	end

	def self.usage_notes
		script_name=$0
		$stderr.puts <<END
Example :
		#{script_name} -u <username> -p <password> --listdir  #lists all directory on ftp server
		#{script_name} -u <username> -p <password> --dir <ftpdir> --backupdir <local_backup_dir> #backup all files from ftp server-dir to local dir
END
	end

	def self.parse(args)
		options= {}
		opts=OptionParser.new do |opts|
			opts.banner = "Usage: #{$0} [options] "

			opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
				options[:verbose] = v
			end

			opts.on("-u", "--userid USERID", String, "ftp user id") do |v|
				options[:userid] = v
			end

			opts.on("-p", "--password PASSWORD", String, "ftp password password") do |v|
				options[:password] = v
			end

			opts.on("-l", "--dir DIRNAME", String, "ftp dir") do |v|
				options[:dir] = v
			end

			opts.on("--listdir", "list all ftp directories") do |v|
				options[:listdir] = v
			end

			opts.on("--backupdir BACKUPDIR", String, "local backup dir") do |v|
				options[:backupdir] = v
			end

			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				usage_notes
				exit(-1)
			end
		end

		opts.parse!(args)
		if validate(options)
			return options
		else
			$stderr.puts "Invalid/no args, see use -h command for help"
			exit(-1)
		end
	end
end
options=FTPOperationsParser.parse(ARGV)

class FTPOperations

	def ftp_login(options)
		ftp=nil
		begin
			ftp = Net::FTP.new
			ftp.connect("127.0.0.1")
			ftp.login(options[:userid], options[:password])
		rescue Exception=>e
			$stderr.puts "#{e.class}:#{e.message}"
		end
		return ftp
	end

	def list_dir(options)
		begin
			raise Exception.new("ftp can't be nil") if not options[:ftp]
			puts options[:ftp].list
		rescue Exception=>e 
			$stderr.puts "exception while listing label:#{e.class}:#{e.message}"
		end
	end

	def bkp_files(options)
		begin
			raise Exception.new("ftp can't be nil") if not options[:ftp]
			raise Exception.new("ftp dir not provided") if not options[:dir]
			raise Exception.new("local backup dir not provided") if not options[:backupdir]

			backup_dir = File.join(options[:backupdir], options[:dir])
			if not File.directory?(backup_dir)
				FileUtils.mkdir_p(backup_dir)
			end

			options[:ftp].chdir(options[:dir])
			options[:ftp].nlst.each do |file|
				begin
					options[:ftp].getbinaryfile(file, File.join(backup_dir, file))
				rescue Net::FTPPermError=> e
					$stderr.puts "skipping dir:#{file}"
				end
			end
		rescue Exception=> e
			$stderr.puts "exception while copying ftp file to local dir:#{e.class}:#{e.message}"
		end
	end
end

ftp_opn_obj = FTPOperations.new
ftp = ftp_opn_obj.ftp_login(options)
if not ftp
	$stderr.puts "could not connect to ftp server."
	exit 1
end

options[:ftp]=ftp
if options[:listdir]
	ftp_opn_obj.list_dir(options)
elsif options[:backupdir] and options[:dir]
	ftp_opn_obj.bkp_files(options)
end
