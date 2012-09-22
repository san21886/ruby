module TransactionExpressionValidity
	def check_expression_validity(expression)
		tokens = expression.split
		if not check_max_3_consecutive_occurances(tokens)
			return false
		end
		if not check_no_repetation(tokens)
			return false
		end
		return true
	end

	#The symbols "I", "X", "C", and "M" can be repeated three times in succession, but no more
	def check_max_3_consecutive_occurances(tokens)
		more_than_3_consecutive_occurance=false
		if tokens.size>=4
			start_index=0
			last_index=3
			while last_index <= tokens.size-1
				slice=tokens[start_index..last_index]
				if slice.uniq.size==1 and ["I", "X", "C", "M"].include?(slice.uniq.first)
					$stderr.puts "#{slice.uniq.first} occurred more than 3 times consecutively"
					more_than_3_consecutive_occurance=true
					break
				end
				start_index+=1
				last_index+=1
			end
		end

		if more_than_3_consecutive_occurance
			return false
		else
			return true
		end
	end

	#"D", "L", and "V" can never be repeated.
	def check_no_repetation(tokens)
		repetation=false
		if tokens.size>1
			["D", "L", "V"].each do |roman|
				slice=tokens.select{|val| val==roman}
				if slice.size>1
					$stderr.puts "#{slice.first} has been repeated"
					repetation=true
					break
				end
			end
		end

		if repetation
			return false
		else
			return true
		end
	end
end

class IntergalacticTransactions
	include TransactionExpressionValidity
	@@roman_numerals_symbol_value={:I=>1, :V=>5, :X=>10, :L=>50, :C=>100, :D=>500, :M=>1000}
	@@substraction_validity_map={:I=>["V", "X"], :X=>["L", "C"], :C=>["D", "M"], :do_no_subtract=>["V", "L", "D"]}
	def initialize(args_hash={})
		super()
	end

	def get_token_value(token)
		token=token.chomp.strip
		num_val=@@roman_numerals_symbol_value[token.to_sym]
		if not num_val
			num_val=@unknown_token_value_map[token]
		end
		return num_val
	end

	def evaluate_quary(token_arr)
		#input like :[I, V, Silver]
		token_value_arr=[]
		sum=0
		token_arr.each do |val|
			num_val=get_token_value(val)
			if not num_val
				$stderr.puts "invalid token:#{val} in tokens:#{token_arr.join(" ")}"
				sum=nil
				break
			else
				token_value_arr.push(num_val)
			end
		end
		return nil if not sum

		index=0
		while index<=token_value_arr.size-1
			if index+1 <= token_value_arr.size-1 and token_value_arr[index]<token_value_arr[index+1]
				if check_substraction_validity(token_value_arr[index+1].to_i, token_value_arr[index].to_i)
					sum+=token_value_arr[index+1].to_i-token_value_arr[index].to_i
					index+=2
				else
					$stderr.puts "invalid substraction:#{token_value_arr[index+1]}-#{token_value_arr[index]}"
					sum=nil
					break
				end
			else
				sum+=token_value_arr[index].to_i
				index+=1
			end
		end
		return sum
	end

	#eg. in expr:glob glob Silver is 34 Credits => I I Silver =>34, considering all operation validity(substraction, repetation..), find the Silver value 
	#returns hash object: {token_name=>token_value}
	def get_unknown_token_val(split_expr)
		#input is like [I, I, Silver, is, 34, Credits]
		sum=split_expr[-2].to_i
		unknown_token_name=split_expr[-4]
		only_tokens=split_expr[0..-4] #[I, I, Silver]
		index=0
		temp_sum=0
		while index+1<=only_tokens.size-1
			break if index+1==only_tokens.size-1
			num_val=get_token_value(only_tokens[index])
			if not num_val
				$stderr.puts "invalid token: #{only_tokens[index]} in the expression:#{split_expr.join(" ")}"
				temp_sum=nil
			end
			num_val2=get_token_value(only_tokens[index+1])
			if not num_val2
				$stderr.puts "invalid token: #{only_tokens[index+1]} in the expression:#{split_expr.join(" ")}"
				temp_sum=nil
			end
			if num_val2 > num_val and check_substraction_validity(num_val2, num_val)
				temp_sum+=num_val2 - num_val
				index+=2
			elsif num_val2 > num_val and not check_substraction_validity(num_val2, num_val)
				$stderr.puts "invalid substraction:#{only_tokens[index+1]} - #{only_tokens[index]}"
				temp_sum=nil
			else
				temp_sum+=num_val
				index+=1
			end
		end
		
		new_token_val=nil	
		if temp_sum
			if index+1==only_tokens.size-1
				remaining_sum=sum.to_i-temp_sum.to_i
				num_val=get_token_value(only_tokens[index])
				if num_val
					if num_val < remaining_sum/2
						new_token_val=remaining_sum.to_i+num_val
					else
						new_token_val=remaining_sum.to_i-num_val
					end
				end
			elsif index==only_tokens.size-1
				new_token_val=sum.to_i-temp_sum.to_i
			end
		end
		return {"#{unknown_token_name}"=>new_token_val}
	end

	def check_substraction_validity(lhs, rhs)
		lhs_key=@@roman_numerals_symbol_value.key(lhs)
		rhs_key=@@roman_numerals_symbol_value.key(rhs)
		if rhs_key and @@substraction_validity_map[:do_no_subtract].include?(rhs_key.to_s)
			return false
		end
		if rhs_key and @@substraction_validity_map[rhs_key] and not @@substraction_validity_map[rhs_key].include?(lhs_key.to_s)
			return false
		end
		return true
	end
end

class IntergalacticTransactionsQuery < IntergalacticTransactions
	def initialize(args_hash={})
		super
		@token_info_ip=[] #glob is I
		@expression_ip=[] #glob glob Silver is 34 Credits
		@quaries=[] #how many Credits is glob prok Silver ?
		@unknown_token_value_map={}
	end

	def get_input_transactions
		$stderr.puts "please input period(.) in new line to end input."
		
		loop do
			ip=STDIN.gets.chomp.strip
			if ip == "."
				break
			end

			if @@roman_numerals_symbol_value.keys.include?(ip.chomp.strip.split.last.to_sym)
				@token_info_ip.push(ip) #statement like : prok is V 
			elsif ip.chomp.strip.split.last.downcase=="credits" #statements like : glob glob Silver is 34 Credits
				@expression_ip.push(ip)
			elsif ip.chomp.strip.split.last=="?" 
				@quaries.push(ip) #statement like : how many Credits is glob prok Gold ?
			else
				$stderr.puts "invalid input:#{ip}"
				$stderr.puts "valid inputs are like:"
				$stderr.puts "glob is I\nglob glob Silver is 34 Credits\nhow many Credits is glob prok Silver ?"
				$stderr.puts "valid roman symbols are:I,V,X,L,C,D,M"
				exit 255
			end
		end
	end

	def process_input_info
		token_roman_map={} #it will hold mapping between new tokens and its corresponding roman symbol:{"glob" => "I", .....}
		@token_info_ip.each do |token_info|
			roman_symbol=token_info.chomp.strip.split.last.chomp.strip
			token=token_info.chomp.strip.split.first.chomp.strip
			token_roman_map[token]=roman_symbol
		end
		find_unknown_token_val(token_roman_map)
		process_quaries(token_roman_map)
	end

	#find val of tokens like: Gold, Iron ... and index it to @unknown_token_value_map:{"Gold" => "57796", ...}
	#eg. in expr:glob glob Silver is 34 Credits => I I Silver =>34, considering all operation validity(substraction, repetation..), find the Silver value 
	def find_unknown_token_val(token_roman_map)
		@expression_ip.each do |expression|
			#expression :glob glob Silver is 34 Credits
			split_expr=[]
			expression.split.each do |val|
				val=val.chomp.strip
				if token_roman_map[val]
					val=token_roman_map[val]

				end
				split_expr.push(val)
			end
			expression_validity=check_expression_validity(split_expr[0..-4].join(" ")) #argument: "I I Silver"
			if not expression_validity
				$stderr.puts "invalid expression:#{expression}"
				exit 1
			end
			token_val_hash=get_unknown_token_val(split_expr)
			token_name=token_val_hash.keys.first
			token_val=token_val_hash.values.first
			if not token_val
				$stderr.puts "invalid token: #{token_name} in the expression:#{expression}"
				exit 1
			else
				@unknown_token_value_map[token_name]=token_val
			end
		end
	end

	def process_quaries(token_roman_map)
		@quaries.each do |expr|
			temp_arr=[]
			#loop for each token in expr like: "how many Credits is glob prok Silver ?"
			token=expr.split(" is ").last
			if not token
				$log.info "invalid expr:#{expr}"
				next
			end
			token=token.split("?").first
			if not token
				$log.info "invalid expr:#{expr}"
				next
			end

			#token like :"glob prok Silver"
			token_arr=[]
			token.split.each do |val|
				val=val.chomp.strip
				if token_roman_map[val]
					val=token_roman_map[val]
				end
				token_arr.push(val)
			end

			expression_valid=check_expression_validity(token_arr.join(" ")) #argument: "I V Silver"
			if not expression_valid
				$stderr.puts "invalid expression:#{expression}"
				next
			end

			val=evaluate_quary(token_arr)
			if val
				puts "#{token} is #{val}"
			else
				puts "I have no idea what you are talking about"
			end
		end
	end
end

obj=IntergalacticTransactionsQuery.new
obj.get_input_transactions
obj.process_input_info
