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

require 'set'

# Handles access to game data:
# * skills
# * schools of magic
# * classes
# * races
class NERO_Skill
	@@initialized = false
	@@skills = {}
	@@initialized = true
	@@schools = []

	# Adds a hash of skills to the array
	def NERO_Skill::add_skills(skills)
		$log.debug "NERO_Skill::add_skills()"
		NERO_Skill::initialize_statics() unless @@initialized
		skills.each do |name, prop|
			$log.debug "Adding skill #{name}"
			skill = NERO_Skill.new(
				name,
				prop['Cost'],
				prop['Requires'],
				prop['Includes'],
				prop['Types'],
				prop['Options'],
				prop['Max'],
				prop['Scholarly'],
				prop['Craftsman'],
				!prop['Invisible'],
				false
			)
			@@skills[name] = skill
		end
	end

	# Adds spells to the skill entries as invisible skills
	# Adds schools to school list
	def NERO_Skill::add_magic schools, costs
		schools.each do |school, data|
			@@schools << school
			(1..9).each do |level|
				costs_prop = {}
				costs.each do |nero_class,cost_data|
					costs_prop[nero_class] = cost_data[level-1]
				end

				if level == 1
					reqs_prop = data['Requires']
				else
					reqs_prop = ["#{school} #{level - 1}"]
				end

				skill = NERO_Skill.new(
					"#{school} #{level}",#name
					costs_prop,          #cost hash
					reqs_prop,           #requirements list
					nil,                 #includes list
					nil,                 #
					nil,                 #options
					0,                   #max
					false,               #scholarly
					false,               #craftsman
					false,               #visible?
					true
				)
				@@skills["#{school} #{level}"] = skill
			end
		end
	end

	# Lists names of schools of magic
	def NERO_Skill::schools()
		@@schools.clone
	end

	# Return the names of the skills, in alphabetical order
	# If $character is instantiated, don't show the skills that the character cannot purchase
	def NERO_Skill::list
		names = []

		@@skills.each do |s|
			if s[1].visible
				if $character.nil?
					names << s[0]
				elsif not s[1].cost($character.character_class.to_s,$character.race.race).nil?
					names << s[0]
				end
			end
		end
		unless $character.nil?
			rdata = $character.race.data()
			$character.race.skills.each_key do |skill|
				names << skill
			end
			unless rdata['Prohibited Skills'].nil?
				rdata['Prohibited Skills'].each do |skill|
					names.delete skill
				end
			end
		end
		names.sort!
		return names
	end


	# Causes NERO_Skill.lookup(copy) to point to skill
	def NERO_Skill::copy skill, copy
		if @@skills.has_key? skill
			return @@skills[copy] = @@skills[skill]
		elsif skill.is_a? NERO_Skill
			return @@skills[copy] = skill
		end
	end

	# Returns a NERO_Skill object by that name
	def NERO_Skill::lookup skill
		if @@skills.has_key? skill.to_s
			return @@skills[skill.to_s]
		end
	end

	##################################
	# Instance Methods:
	##################################
	attr_reader :name, :cost, :prereqs, :includes, :types, :options, :limit, :scholarly, :craftsman, :prohibits, :visible, :spell

	def initialize(
		skill_name,
		cost,
		prereqs = nil,
		includes = nil,
		types = nil,
		options = nil,
		limit = nil,
		scholarly = nil,
		craftsman = nil,
		visible = nil,
		spell = nil)
		# Example Parameters:
		# skill_name = "Smithing",
		# cost = {'Dwarf Fighter' => 2,
		#         'Dwarf Templar' => 2,
		#         'Dwarf Scholar' => 3,
		#         'Dwarf Rogue' => 3,
		#         'Fighter' => 3,

		#         'Templar' => 3,
		#         'Scholar' => 4,
		#         'Rogue' => 4},
		# prereqs = [], # Smithing has no prereqs (read/write is a typo)
		# includes = [],
		# options = [],
		# limit = 0 # no limit to the number of purchases of smithing
		# scholarly = false
		# craftsman = false
		# visible = true
		@name = skill_name
		@cost = cost

		@prereqs = []
		@includes = []
		@types = []
		@options = []
		@limit = 1
		@scholarly = false
		@craftsman = false
		@visible = true
		@spell = false

		@prereqs   = prereqs   unless prereqs.nil?
		@includes  = includes  unless includes.nil?
		@types     = types     unless types.nil?
		@options   = options   unless options.nil?
		@limit     = limit     unless limit.nil?
		@scholarly = scholarly unless scholarly.nil?
		@craftsman = craftsman unless craftsman.nil?
		@visible   = visible   unless visible.nil?
		@spell     = spell     unless spell.nil?
	end

	# Find the base cost for this skill for a class/race combo
	# Note that this may be an integer OR may be an array
	def cost class_name, race
		if @prohibits != nil and (@prohibits.include?(race) or @prohibits.include?(class_name))
			return nil
		end
		if !@cost.is_a? Hash
			return @cost
		end
		# Allowed, but discouraged.  It's preferable to define racial changes to skill costs through the
		# race section.
		if @cost.has_key? "#{race} #{class_name}"
			return @cost["#{race} #{class_name}"]
		end
		if @cost.has_key? race
			return @cost[race]
		end
		if @cost.has_key? class_name
			return @cost[class_name]
		end

		# Cost not found: This is our way of throwing an error
		return nil
	end

	# Determine the count that this skill should be set to, given its current amount
	def apply_limit amount
		if @limit.is_a? Integer
			limit = @limit
		elsif @limit.is_a? Hash
			limit = @limit[$character.character_class.to_s]
		else
			limit = 0
		end

		if limit <= 0
			return amount
		end
		if limit < amount
			return limit
		end
		return amount
	end

	# Return the skill's name
	def to_s
		@name.to_s
	end

	# If this counts as a prereq for the listed skill, return true
	def fulfills_prereq?( prereq )
		@includes.each do |i|
			if i == prereq
				return true
			else
				recurse = NERO_Skill.lookup(i)
				if recurse.is_a? NERO_Skill and recurse.fulfills_prereq?(prereq)
					return true
				end
			end
		end
		return false
	end

	# Find skills that this skill could replace.
	def get_all_includes includes = nil, recurse = nil
		if includes == nil
			if @includes.is_a? Array
				includes = @includes
			elsif @includes.is_a? Hash
				return @includes
			else
				$log.warn "NERO_Skill(#{@name}) has includes in an invalid format!"
				return []
			end
		end
		recurse = 0 if recurse == nil

		$log.debug "#{@name}.get_all_includes(#{includes.inspect},#{recurse})"

		return includes if recurse >= 5 or includes.nil?
		extra_includes = []
		includes.each do |skill_name|
			nskill = NERO_Skill.lookup(skill_name)
			next if nskill.nil?
			extra_includes = extra_includes + nskill.includes unless nskill.includes.nil?
		end
		extra_includes = extra_includes - includes
		includes = Set.new(includes + extra_includes).to_a
		if extra_includes.empty?
			$log.info "#{@name}.get_all_includes() = #{includes.inspect}"
			return includes
		end
		return get_all_includes(includes, recurse + 1)
	end

	def inspect
		s = "#{@name}"
		if @scholarly
			s += " (Scholarly)"
		end
		s += ":"

		s += " Cost: {|"
		if @cost.is_a? Hash
			@cost.each do |raceclass, cost|
				if cost.is_a? Array
					s += "#{raceclass}=>[|"
					cost.each { |c|
						s += "#{c}|"
					}
					s += "]"
				else
					s += "#{raceclass}=>#{cost}|"
				end
			end
			s += "}"
		else
			s += "#{@cost}|}"
		end

		if @prereqs != nil
			s += " Prereqs:"
			if @prereqs.is_a? Array
				s += "[|"
				@prereqs.each do |p|
					s += "#{p}|"
				end
				s += "]"
			elsif @prereqs.is_a? Hash
				s += "{|"
				@prereqs.each do |p,count|
					s += "#{p}=>#{count}|"
				end
				s += "}"
			else
				s += "#{@prereqs}|}"
			end
		end

		if @options != nil
			s += " Options:"
			if @options.is_a? Array
				s += "[|"
				@options.each do |o|
					s += "#{o}|"
				end
				s += "]"
			else
				s += "'#{@options}'"
			end
		end

		if @includes != nil
			s += " Includes:"
			if @includes.is_a? Array
				s += "[|"
				@includes.each do |i|
					if s.is_a? Hash
						s += "{|"
						i.each do |ii, count|
							s += "#{i}=>#{count}|"
						end
						s += "}"
					end
					s += "#{i}|"
				end
				s += "]"
			elsif @includes.is_a? Hash
				s += "{|"
				@includes.each do |i,cost|
					s += "#{i}=>#{cost}|"
				end
				s += "}"
			else
				s += "'#{@includes}'"
			end
		end
		return s
	end

end

if __FILE__ == $0
	$log = Logger.new('nero_skills.log',10,102400)
	$log.info "Testing nero_skills.rb"
	$log.warn "Nothing to test!"
end

