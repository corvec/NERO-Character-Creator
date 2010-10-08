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


class NERO_Race
	@@race_list = []
	@@race_data = {}
	@@default_race = 'Human'
	@@initialized = false
	attr_reader :race

	def NERO_Race::add_races(race_data)
		$log.debug "NERO_Race::add_races()"
		race_data.each do |race, data|
			unless @@race_list.include? race
				@@race_list << race
				if data['Default'] == true
					@@default_race = race
				end
				@@race_data[race] = data
			else
				data.each do |category, cat_data|
					unless @@race_data[race].has_key? category
						@@race_data[race][category] = cat_data
					else
						if @@race_data[race][category].is_a? Hash
							cat_data.each do |cat_key,cat_val|
								@@race_data[race][category][cat_key]=cat_val
							end
						elsif @@race_data[race][category].is_a? Array
							@@race_data[race][category] = @@race_data[race][category] + cat_data
						else
							@@race_data[race][category] = cat_data
						end
					end
				end
			end
		end
		@@race_list.sort!
		@@initialized = true
	end

	def initialize(race = nil)
		race = @@default_race if race.nil?
		self.race= race
	end

	def NERO_Race::list
		@@race_list.clone
	end

	def to_s
		return race
	end

	def race= race
		if @@race_list.include? race
			@data = @@race_data[race]
			return @race = race
		end
		if race.is_a? Integer and race < @@race_list.length
			@data = @@race_data[@@race_list[race]]
			return @race = @@race_list[race]
		end
		return false
	end

	def data
		@@race_data[@race].clone
	end

	def prohibited? skill
		skill_name = skill.to_s

		prohib = self.data['Prohibited Skills']
		return prohib && prohib.include?(skill_name)
	end

	def abilities
		if self.data['Abilities'].nil?
			[]
		else
			self.data['Abilities']
		end
	end

	
	def skill_cost_modifiers skill
		mods = []

		mods << :doubled if @data.has_key?('Double Cost for Skills') and @data['Double Cost for Skills'].include? skill
		mods << :halved  if @data.has_key?('Half Cost for Skills') and @data['Half Cost for Skills'].include? skill
		mods << :reduced if @data.has_key?('Reduced Cost for Skills') and @data['Reduced Cost for Skills'].include? skill
		
		return mods
	end

	def body
		b = @data['Starting Body']
		return b.to_i unless b.nil?
		return 0
	end

	# Returns hash of racial skills, where {skill.to_s => skill.cost}
	def skills
		return {} unless self.data['Racial Skills'].is_a? Hash
		return self.data['Racial Skills']
	end
end



# Local Testing
if __FILE__ == $0
	$log = Logger.new('nero_race.log',10,102400)
	$log.info "Testing nero_race.rb"


	NERO_Race.initialize_statics(YAML.load('ncc_data.yml')['Races'])
	nero_race = NERO_Race.new 'Scavenger'

	require 'irb'
	require 'irb/completion'
	IRB.start
end
