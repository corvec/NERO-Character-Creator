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

# Handles access to the list of skills
class NERO_Skills
	attr_reader :skills
	def initialize(filename = $config.setting('Skill Data'))
		$log.info "Initializing Skills"
		@skills = {}
		self.add_file(filename)
		num = 1
		until $config.setting("Module #{num}").nil?
			begin
				self.add_file($config.setting)
			rescue
				begin
					$log.info("Could not load Module #{$config.setting} in current directory.  Trying working directory.")
					self.add_file("#{$config.setting('Working Directory')}/#{$config.setting("Module #{num}")}")
				rescue
					$log.error("Could not load Module #{$config.setting}")
				end
			end
			num += 1
		end
	end

	def add_file filename
		$log.info "Adding file #{filename} to skill list"
		skills = YAML::load(File.open(filename))
		skills.each do |name, prop|
			skill = NERO_Skill.new(
				name,
				prop['Cost'],
				prop['Requires'],
				prop['Includes'],
				prop['Options'],
				prop['Max'],
				prop['Scholarly'],
				prop['Prohibits'],
				(not prop['Invisible'])
			)
			@skills[name] = skill
		end
	end

	# Return the names of the skills, in alphabetical order
	def skill_names
		names = []
		@skills.sort.each do |s|
			names << s[0] if s[1].visible
		end
		return names
	end

	# Causes $nero_skills.lookup(copy) to point to skill
	def copy skill, copy
		if @skills.has_key? skill
			return @skills[copy] = @skills[skill]
		elsif skill.is_a? NERO_Skill
			return @skills[copy] = skill
		end
	end

	def lookup skill
		if skill.is_a? String
			if @skills.has_key? skill
				return @skills[skill]
			end
		end
	end
end

# Stored in NERO_Skills
class NERO_Skill
	attr_reader :name, :cost, :prereqs, :includes, :options, :limit, :scholarly, :prohibits, :visible
	def initialize(
		skill_name,
		cost,
		prereqs = nil,
		includes = nil,
		options = nil,
		limit = nil,
		scholarly = nil,
		prohibits = nil,
		visible = nil)
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
		# options = {},
		# limit = 0 # no limit to the number of purchases of smithing
		@name = skill_name
		@cost = cost

		@prereqs = []
		@includes = []
		@options = []
		@limit = 1
		@scholarly = false

		@prereqs   = prereqs   if prereqs != nil
		@includes  = includes  if includes != nil
		@options   = options   if options != nil
		@limit     = limit     if limit != nil
		@scholarly = scholarly if scholarly != nil
		@prohibits = prohibits
		@visible   = visible
	end

	def cost class_name, race
		if @prohibits != nil and (@prohibits.include?(race) or @prohibits.include?(class_name))
			return nil
		end
		if !@cost.is_a? Hash
			return @cost
		end
		if @cost.has_key? "#{race} #{class_name}"
			return @cost["#{race} #{class_name}"]
		end
		if @cost.has_key? race
			return @cost[race]
		end
		if @cost.has_key? class_name
			if (%w(Barbarian Half\ Ogre Half\ Orc Scavenger).include? race) and @scholarly
				return 2 * @cost[class_name]
			else
				return @cost[class_name]
			end
		end

		# Cost not found: This is our way of throwing an error
		return nil
	end

	def apply_limit amount
		if @limit == 0
			return amount
		end
		if @limit < amount
			return @limit
		end
		return amount
	end

	def to_s
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

	def fulfills_prereq?( prereq )
		@includes.each do |i|
			if i == prereq
				return true
			else
				recurse = $nero_skills.lookup(i)
				if recurse.is_a? NERO_Skill and recurse.fulfills_prereq?(prereq)
					return true
				end
			end
		end
		return false
	end

	def is_a_spell?
		@name.match /\w \d/
	end

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
			nskill = $nero_skills.lookup(skill_name)
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


end

if __FILE__ == $0
	$log = Logger.new('nero_skills.log',10,102400)
	$log.info "Testing nero_skills.rb"
	$log.warn "Nothing to test!"
end

