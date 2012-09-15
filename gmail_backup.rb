require 'net/imap'
require 'optparse'
require 'fileutils'

class GmailOperationsParser
	
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
		#{script_name} -u <username> -p <password> --listlabel #lists all label 
		#{script_name} -u <username> -p <password> --label <label_name> --backupdir <backup_dir> #backup all mails from the label
END
	end

	def self.parse(args)
		options= {}
		opts=OptionParser.new do |opts|
			opts.banner = "Usage: #{$0} [options] "

			opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
				options[:verbose] = v
			end

			opts.on("-u", "--userid USERID", String, "gmail user id") do |v|
				options[:userid] = v
			end

			opts.on("-p", "--password PASSWORD", String, "gmail password") do |v|
				options[:password] = v
			end

			opts.on("-l", "--label LABEL", String, "mail box label like - inbox") do |v|
				options[:label] = v
			end

			opts.on("--listlabel", "list all mail boxes - labels for given userid and password") do |v|
				options[:listlabel] = v
			end

			opts.on("--backupdir BACKUPDIR", String, "mail archive dir") do |v|
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
options=GmailOperationsParser.parse(ARGV)

class GmailOperations

	def account_login(options)
		imap=nil
		begin
			imap = Net::IMAP.new("imap.gmail.com", 993, true)
			imap.login(options[:userid], options[:password])
		rescue Exception=>e
			$stderr.puts "#{e.class}:#{e.message}"
		end
		return imap
	end

	def list_labels(options)
		begin
			raise Exception.new("imap can't be nil") if not options[:imap]
			options[:imap].list("", "%").each{|label| puts label.name} #mathced everything except hierarchy delimiter - '/'
			#options[:imap].list("", "*").each{|label| puts label.name} #mathced everything including hierarchy delimiter - '/'
		rescue Exception=>e 
			$stderr.puts "exception while listing label:#{e.class}:#{e.message}"
		end
	end

	def bkp_mails(options)
		begin
			raise Exception.new("imap can't be nil") if not options[:imap]
			raise Exception.new("mailbox label not provided") if not options[:label]
			raise Exception.new("mailbox backup dir not provided") if not options[:backupdir]

			backup_dir = File.join(options[:backupdir], options[:label])
			if not File.directory?(backup_dir)
				FileUtils.mkdir_p(backup_dir)
			end

			file_ts=Time.now.to_s.split[0..1].join.gsub(/\-|:/,"")
			options[:imap].examine(options[:label])
			options[:imap].search(["ALL"]).each do |mailid|
				#to watch mail body
				#puts options[:imap].fetch(mailid, "BODY[TEXT]")[0].attr["BODY[TEXT]"] 
				fetched = options[:imap].fetch(mailid, "RFC822")[0].attr["RFC822"] 
				File.open(File.join(backup_dir, file_ts), "a") do |file|
					file << fetched
				end
			end
		rescue Exception=> e
			$stderr.puts "exception while backing up mailbox:#{e.class}:#{e.message}"
		end
	end
end

gmail_opn_obj = GmailOperations.new
imap = gmail_opn_obj.account_login(options)
if not imap
	$stderr.puts "could not connect to mail imap server."
	exit 1
end

options[:imap]=imap
if options[:listlabel]
	gmail_opn_obj.list_labels(options)
elsif options[:backupdir] and options[:label]
	gmail_opn_obj.bkp_mails(options)
end
