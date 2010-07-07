#!/usr/bin/env ruby

=begin
	This file is part of the NERO Character Creator.

	NERO Character Creator is free software: you can redistribute it
	and/or modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation, either version 3 of
	the License, or (at your option) any later version.

	NERO Character Creator is distributed in the hope that it will
	be useful, but WITHOUT ANY WARRANTY; without even the implied
	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with the NERO Character Creator.
	If not, see <http://www.gnu.org/licenses/>.
=end

require 'date'

class Experience
	@@xp_per_bp_at_level = []

	attr_reader :build, :experience, :history, :loose, :trail

	def Experience::initialize_statics
		cur = 0
		(3..999).each do |i|
			cur += i
			@@xp_per_bp_at_level << cur
		end
	end

	def initialize(experience = nil, build=nil)
		if @@xp_per_bp_at_level.length == 0
			Experience.initialize_statics()
		end

		@experience = 65 # Total Experience
		@loose = 0 # Loose experience (after this build)
		@build = 30 # Total build
		@history = [] # History for the purpose of undoing actions
		@trail = [] # String trail, for YAML export
		@traild= [] # Data trail, for YAML export

		if experience != nil or build != nil
			if build != nil
				self.build= build
			end
			if experience != nil
				self.experience= experience
			end
		end
	end

public
	def to_i
		return @experience
	end

	def to_s
		s = "Experience:\n"
		@trail.each do |t|
			s += t
		end
		return s
	end

	def export
		@traild.clone
	end

	def level
		@build/10 - ((@build > 4+(10*(@build/10))) ? 0 : 1)
	end

public
	def experience=( amount )
		if amount.to_i == 0
			return
		end
		if amount.integer?
			@history << [@experience,@build,@loose,'experience=',amount]
			@experience = amount
			calculate_build
		end
	end

	def loose= amount
		if amount.integer?
			diff = amount - @loose
			@loose = amount
			self.add_experience diff
			while @loose > Experience::xp_required_per_bp(self.level())
				@loose -= Experience::xp_required_per_bp(self.level())
				@build += 1
			end
		end
	end


protected
	# Add <amount> experience,
	# update build,
	# set loose experience
	def add_experience amount
		if amount.integer?
			exp = amount + @loose
			@loose = 0
			@experience += amount
			while exp >= Experience::xp_required_per_bp(self.level())
					exp -= Experience::xp_required_per_bp(self.level())
					@build += 1
			end
			@loose = exp
		end
	end


protected
	# Calculate build given the value of @experience
	def calculate_build
		exp = @experience
		bp = 15
		level = 1
		while exp > 0
			if (exp - Experience::xp_required_per_level(level)) >= 0
				exp -= Experience::xp_required_per_level(level)
				level += 1
				bp += 10
			else
				while exp >= Experience::xp_required_per_bp(level)
					exp -= Experience::xp_required_per_bp(level)
					bp += 1
				end
				loose_xp = exp
				exp = 0
			end
		end
		@build = bp
		@loose = loose_xp
		return [bp, loose_xp]
	end

	def update_history info, amount
		@history << [@experience,@build,@loose,info,amount]
	end

public
	# Set the build and calculate experience
	def build= amount
		update_history 'build=', amount
		if !amount.is_a?(Integer) or amount < 15
			return false
		end
		@build = amount
		@loose = 0
		self.calculate_experience()
	end

protected
	# Set @experience based on @build
	# Called by build=()
	def calculate_experience
		@experience = 0
		b = 15
		while b < @build
			if @build - b > 10
				@experience += Experience::xp_required_per_level( b/10 - ((b>4+(10*(b/10)))?0:1) )
				b += 10
			else
				@experience += Experience::xp_required_per_bp(b/10 - ((b>4+(10*(b/10)))?0:1) )
				b += 1
			end
		end
	end


public
	# Set the characters build to amount * 10 + 5
	# This will reset the experience
	def level= amount
		if !amount.is_a?(Integer) or amount <= 0
			return false
		end
		self.build= amount * 10 + 5
	end


	# At a given level, how much exp does it take to get a build?
	def Experience::xp_required_per_bp level
		@@xp_per_bp_at_level[level-1]
	end
	
	# At a given level, how much exp does it take to get to the next level?
	def Experience::xp_required_per_level level
		xp_required_per_bp(level) * 10
	end

	# Used for events
	def add_blankets count
		self.add_experience((@build * count).round)
	end

	# Used for goblin blankets
	# Would also be used for a lot of events simultaneously
	def add_sequential_blankets num_of_blankets, num_of_series
		num_of_series.times do
			self.add_blankets num_of_blankets
		end
	end

public
	

	def load yaml_data
		if yaml_data.is_a? Hash and yaml_data.has_key? 'Experience'
			data = yaml_data['Experience']
		else
			data = yaml_data
		end

		data = [] if data.nil?

		@trail = []
		@traild= []
		# For Experience::undo
		@history = []
		@experience = 65
		@build = 30
		@loose = 0
		data.each do |exp|
			case exp['Type']
			when 'Custom' then
				self.add_custom(exp['Number'].to_f,exp['Times'].to_i)
			when 'Goblin Blanket' then
				self.add_goblin_blankets(exp['Date'],exp['Number'].to_i)
			when 'PC Event' then
				self.add_pc_event(exp['Site'],exp['Date'],exp['Days'].to_f,exp['Maxout'])
			when 'NPC Event' then
				self.add_npc_event(exp['Site'],exp['Date'],exp['Days'].to_f,exp['Maxout'])
			when 'Reset' then
				hash = {}
				hash[:experience] = exp['Experience']
				hash[:build] = exp['Build']
				hash[:level] = exp['Level']
				hash[:loose] = exp['Loose']
				self.reset(hash)
			end
		end
	end

	# Undo the last operation in history
	def undo
		if @history.length <= 0
			return false
		end
		item = @history.pop
		@trail.pop
		@traild.pop
		if item.length > 3
			@experience = item[0]
			@build = item[1]
			@loose = item[2]
			return true
		end
	end

	def add_goblin_blankets date, amount
		trail_string  = "   - Type: Goblin Blanket\n"
		trail_string += "     Date: #{date}\n"
		trail_string += "     Number: #{amount}\n"
		trail_data = {"Type" => "Goblin Blanket", "Date" => date, "Number" => amount}

		@trail << trail_string
		@traild<< trail_data
		
		update_history 'goblins', amount * @build
		self.add_sequential_blankets 1, amount.to_i
	end

	def add_pc_event event_name, date, days, maxout
		trail_string  = "   - Type: PC Event\n"
		trail_string += "     Site: #{event_name}\n"
		trail_string += "     Date: #{date}\n"
		trail_string += "     Days: #{days}\n"
		trail_string += "     Maxout: #{maxout}\n"
		trail_data   = {"Type" => "PC Event","Site" => event_name, "Date"=>date,"Days"=>days,"Maxout"=>maxout}

		@trail << trail_string
		@traild<< trail_data

		# maxout can be true, false, or an integer
		if maxout == false or maxout == true
			b = (maxout ? days : 0.5 * days )

			update_history 'pc event', b * @build
			self.add_blankets b
		else
			experience = @build
			maxout = maxout.to_i
			if maxout > @build
				$log.warn "Maxout requested too big by #{maxout - @build}"
				experience += @build
			else
				experience += maxout
			end

			update_history 'pc event', experience
			self.add_experience experience
		end
	end

	def add_npc_event event_name, date, days, maxout
		trail_string  = "   - Type: NPC Event\n"
		trail_string += "     Site: #{event_name}\n"
		trail_string += "     Date: #{date}\n"
		trail_string += "     Days: #{days}\n"
		trail_string += "     Maxout: #{maxout}\n"
		trail_data    = {"Type" => "NPC Event", "Site" => event_name, "Date"=>date,"Days"=>days,"Maxout"=>maxout}

		@trail << trail_string
		@traild<< trail_data

		b = days / 2.0
		if maxout == true
			b *= 2
		end

		update_history 'npc event', b
		self.add_blankets b

	end

	def add_custom num_of_blankets, num_of_series
		trail_string  = "   - Type: Custom\n"
		trail_string += "     Number: #{num_of_blankets}\n"
		trail_string += "     Times: #{num_of_series}\n"
		trail_data    = {"Type" => "Custom", "Number" => num_of_blankets, "Times" => num_of_series}

		@trail << trail_string
		@traild<< trail_data
		
		update_history 'custom',  num_of_blankets * num_of_series * @build
		add_sequential_blankets num_of_blankets, num_of_series
	end


	def reset data = {}
		trail_string  = "   - Type: Reset\n"

		trail_data = {"Type"=>"Reset"}

		if !data[:experience].nil?
			trail_string += "     Experience: #{data[:experience]}\n"
			trail_data["Experience"] = data[:experience]
		end
		if !data[:build].nil?
			trail_string += "     Build: #{data[:build]}\n"
			trail_data["Build"] = data[:build]
		end
		if !data[:level].nil?
			trail_string += "     Level: #{data[:level]}\n"
			trail_data["Level"] = data[:level]
		end
		if !data[:loose].nil?
			trail_string += "     Loose: #{data[:loose]}\n"
			trail_data["Loose"] = data[:loose]
		end

		@trail << trail_string
		@traild<< trail_data

		if !data[:experience].nil?
			self.experience= data[:experience]
		end

		if !data[:build].nil?
			self.build= data[:build]
		end

		if !data[:level].nil?
			self.build= data[:level] * 10 + 5
		end

		if !data[:loose].nil? and loose > 0
			self.loose= data[:loose]
		end
	end
end


def e_data e
	$log.info e
	$log.info "Experience: #{e.experience}"
	$log.info "Build: #{e.build}"
	$log.info "Loose: #{e.loose}"
	$log.info "Level: #{e.level}"
end

# Testing the experience module
if __FILE__ == $0
	$log = Logger.new('experience.log',10,102400)
	$log.info "Testing experience.rb"



	$log.info "> e = Experience.new()"
	e = Experience.new()
	e_data(e)
	
	$log.info "> e.add_goblin_blankets(Date.new(2009,4,11),4)"
	e.add_goblin_blankets(Date.new(2009,4,11),4)
	e_data(e)

	$log.info "> e.add_pc_event('Ashton',Date.new(2008,5,14),2,true)"
	e.add_pc_event('Ashton',Date.new(2008,5,14),2,true)
	e_data(e)

	$log.info "> e.add_npc_event('Vargus',Date.new(2008,6,6),2,true)"
	e.add_npc_event('Vargus',Date.new(2008,6,6),2,true)
	e_data(e)

	$log.info "> e.add_pc_event('Oasis',Date.new(2008,7,18),2,100)"
	e.add_pc_event('Oasis',Date.new(2008,7,18),2,100)
	e_data(e)

	$log.info "> e.reset('Test',Date.new(2008,8,25),43650)"
	e.reset("Test",Date.new(2008,8,25),43650)
	e_data(e)
	
	$log.info "> e.reset('Test',Date.new(2008,8,25),nil,206,nil)"
	e.reset("Test",Date.new(2008,8,25),nil,206,nil)
	e_data(e)
	e.reset("Test",Date.new(2008,8,25),nil,204,75)
	e_data(e)
	
=begin	
	$log.info "> e.undo"
	e.undo
	e_data(e)
	
	$log.info "> e.undo"
	e.undo
	e_data(e)
	
	$log.info "> e.undo"
	e.undo
	e_data(e)
	
	$log.info "> e.undo"
	e.undo
	e_data(e)
	
	$log.info "> e.undo"
	e.undo
	e_data(e)
	
	$log.info "> e.undo"
	e.undo
	e_data(e)
	
	$log.info "> e.undo"
	e.undo
	e_data(e)
=begin
=end
	
end
