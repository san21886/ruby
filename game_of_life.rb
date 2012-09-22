class Cell
	attr_accessor :cell_row_index, :cell_col_index, :cell_state
	def initialize(args_hash={})
		super()
		if not args_hash[:ip] or (args_hash[:ip]!="x" and args_hash[:ip]!="-") or not args_hash[:row_index] or not args_hash[:col_index]
			$stderr.puts "error occurred due to one of following reasons:"
			$stderr.puts "input provided is not among x and -"
			$stderr.puts "cell's row and col index could not be assigned"
			exit 255
		end
		if args_hash[:ip]=="x"
			@cell_state="live"
		elsif args_hash[:ip]=="-"
			@cell_state="dead"
		end
		@cell_row_index=args_hash[:row_index]
		@cell_col_index=args_hash[:col_index]
	end

	def set_cell_state(state)
		@cell_state=state
	end

	#horizontal left 
	def get_cell_hleft_neighbour_index
		return [@cell_row_index, @cell_col_index-1]
	end

	#horizontal right
	def get_cell_hright_neighbour_index
		return [@cell_row_index, @cell_col_index+1]
	end

	#vertical up
	def get_cell_vup_neighbour_index
		return [@cell_row_index-1, @cell_col_index]
	end

	#vertical down
	def get_cell_vdown_neighbour_index
		return [@cell_row_index+1, @cell_col_index]
	end

	#digonal left down
	def get_cell_dldown_neighbour_index
		return [@cell_row_index+1, @cell_col_index-1]
	end

	#digonal right down
	def get_cell_drdown_neighbour_index
		return [@cell_row_index+1, @cell_col_index+1]
	end

	#digonal left up
	def get_cell_dlup_neighbour_index
		return [@cell_row_index-1, @cell_col_index-1]
	end

	#digonal right up
	def get_cell_drup_neighbour_index
		return [@cell_row_index-1, @cell_col_index+1]
	end
end

class GameOfLife

	def initialize
		super
		@col_count=0
		@row_count=0
		@cells_arr=[]
	end

	def start_game
		initialize_grid
		process_each_cell
		for row_index in 0..(@row_count-1)
			for col_index in 0..(@col_count-1)
				index=get_cells_index(row_index, col_index)
				next if not index
				if @cells_arr[index].cell_state=="live"
					print "x"
				else
					print "-"
				end
			end
			print "\n"
		end
	end

	def initialize_grid
		$stderr.puts "input seed:(x/-)"
		$stderr.puts "input period(.) in new line to end input"
		@cells_arr=[]
		loop do 
			ip=STDIN.gets.gsub(/\s*/, "").chomp.strip
			cols=[]
			ip.each_char{|char| cols.push(char)}
			arr_size=cols.size

			if cols.first=="."
				break
			end

			if @col_count==0
				@col_count=arr_size
			elsif @col_count!=arr_size
				$stderr.puts "invalid grid"
				exit 255
			end

			index=0
			cols.each do |val| 
				arg_hash={:ip=>val.chomp.strip.downcase,:row_index=>@row_count, :col_index=>index}
				@cells_arr.push(Cell.new(arg_hash))
				index+=1
			end
			@row_count+=1
		end
	end

	def process_each_cell
		new_states=[]
		@cells_arr.each do |cell_obj|
			neighbours_state=get_cell_neighbours_state(cell_obj)
			live_states=neighbours_state.select{|state| state=="live"}
			dead_states=neighbours_state.select{|state| state=="dead"}
			if live_states.size < 2 or live_states.size > 3
				index=get_cells_index(cell_obj.cell_row_index, cell_obj.cell_col_index)
				new_states[index]="dead"
			elsif live_states.size == 3 and cell_obj.cell_state=="dead"
				index=get_cells_index(cell_obj.cell_row_index, cell_obj.cell_col_index)
				new_states[index]="live"
			else
				index=get_cells_index(cell_obj.cell_row_index, cell_obj.cell_col_index)
				new_states[index]=cell_obj.cell_state
			end
		end

		index=0
		new_states.each do |state|
			@cells_arr[index].set_cell_state(state)
			index+=1
		end
	end

	def get_cell_neighbours_state(cell_obj)
		neighbour_indexes=[]
		[cell_obj.get_cell_hleft_neighbour_index, cell_obj.get_cell_hright_neighbour_index, cell_obj.get_cell_vup_neighbour_index, cell_obj.get_cell_vdown_neighbour_index, cell_obj.get_cell_dldown_neighbour_index, cell_obj.get_cell_drdown_neighbour_index, cell_obj.get_cell_dlup_neighbour_index, cell_obj.get_cell_drup_neighbour_index].each do |index_arr|
			index=get_cells_index(index_arr.first, index_arr.last)
			neighbour_indexes.push(index) if index
		end
		neighbour_indexes.map!{|index| @cells_arr[index].cell_state}
		neighbours_state=neighbour_indexes
		return neighbours_state
	end

	def get_cells_index(row_index, col_index)
		cells_index=nil
		if row_index < 0 or row_index>@row_count-1 or col_index >@col_count-1 or col_index<0
			cells_index=nil
		else
			cells_index=@col_count*(row_index) + col_index
		end
		return cells_index
	end
end

GameOfLife.new.start_game
