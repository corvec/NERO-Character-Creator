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

class Character_Skill
	attr_reader :count, :options, :skill
	def initialize nero_skill, options, amount = 1, character = nil
		@skill = nero_skill
		@options = options
		amount = amount.to_i
		#puts "New Character Skill: #{amount}x #{nero_skill.name} (#{options})"
		if amount.is_a? Integer
			@count = nero_skill.apply_limit(amount)
		else
			@count = 1
		end
		#Debug message:
		if @count != amount.to_i
			puts "Character_Skill.new(): Limited amount to #{@count}"
		end
		@character = character
	end

	def count= amount
		if amount.to_i > 0
			@count = @skill.apply_limit(amount)
		end
	end

	def name
		return @skill.name
	end

	def legal? class_name = nil, race = nil
		if @character != nil
			class_name = @character.character_class.to_s if class_name == nil
			race = @character.race.to_s if race == nil
		end
		if @skill.prohibits != nil
			if @skill.prohibits.include?(race) or @skill.prohibits.include?(class_name)
				return false
			end
		end
		return true
	end

	# Returns the cost of this skill
	# Accounts for the primary school of the character with spells
	# Accounts for templar profs
	# Accounts for critical attacks if passed a reference to the character's build
	def cost class_name = nil, race = nil, primary_school='Earth', build=nil
		if @character != nil
			class_name     = @character.character_class.to_s if class_name     == nil
			race           = @character.race.to_s            if race           == nil
			primary_school = @character.primary              if primary_school == nil
			build          = @character.build                if build          == nil
		end

		if !self.legal?
			return false
		end

		# Secondary spells:
		#if @skill.name.match('\w* \d') and !@skill.name.match("#{primary_school} \\d")
			#return 2 * @count * @skill.cost(class_name, race)
		#end

		cost = @skill.cost(class_name, race)
		if cost.is_a? Integer
			return @count * cost
		end
		# Prohibited or racial
		if cost == nil
			return false
		end
		# Must be a templar purchasing profs or crit attacks
		# (or a rogue getting master profs / master crit attacks)
		# TODO: check build to see if there are profs if this is a crit att
		if @skill.name.match('Attack')
			set = 0
			if build != nil
				if @skill.name.match('Master')
					set = build.count('Master Proficiency', @options)
					set = 2 if set > 2
				else
					set = build.count('Proficiency', @options)
					set = 2 if set > 2
				end
			end
			return @count * cost[set]
		end
		# must be a prof:
		# Note that this implementation assumes that you can have a 
		# minimum priced first master prof and a minimum priced first prof
		# This may not be legitimate.
		if @count >= 3
			return cost[0] + cost[1] + (cost[2]*(@count-2))
		end
		if @count == 2
			return cost[0] + cost[1]
		end
		return cost[0]
	end

	# Returns true if the passed skill includes this one (recursive)
	def is_included_in?(skill)
		skill.includes.each do |inc|
			if inc.to_s == @skill.name.to_s
				skill_inc = $nero_skills.lookup(inc)
				if !skill_inc.is_a? NERO_Skill
					next
				end
				if skill_inc.limit == 1
					return true
				else
					next
				end
			end
			recurse = $nero_skills.lookup(inc)
			if recurse.is_a?(NERO_Skill) and self.is_included_in?(recurse)
				return true
			end
		end
		return false
	end

	# Returns true if this skill fulfills the required prereq
	# If count == 0, it returns true if its name or its includes
	# match prereq and false otherwise
	# If count != 0, it returns true if self.count > count
	# Otherwise, it returns count - self.count
	def fulfills_prereq? prereq, count = 0
		if prereq == nil
			return true
		end

		prereq = prereq.to_s
		#puts "Character_Skill(#{@skill.name}).fulfills_prereq(#{prereq})"

		if @skill.name == prereq
			return check_prereq_count(count)
		end

		# Check to see if it or any of the includes match it
		@skill.includes.each do |inc|
			if inc.to_s == prereq
				temp = check_prereq_count(count)
				return temp
			end
			recurse = $nero_skills.lookup(inc)
			if recurse == nil
				next
			end
			if recurse.fulfills_prereq?(prereq)
				temp = check_prereq_count(count)
				return temp
			end
		end
		return false
	end

	def check_prereq_count count
		if @count >= count
			#puts "Character_Skill(#{@skill.name}).check_prereq_count() : returning true"
			return true
		end
		puts "Character_Skill(#{@skill.name}).check_prereq_count() : returning #{count - @count}"
		return count - @count
	end

	# Returns true if the prereqs of this skill are fulfilled by
	# the existing build.
	# This also checks to ensure that skills such as Slays
	# are at a legal total amount, given the amount of proficiencies
	def meets_prerequisites? build = nil, my_count = @count
		#puts "Character_Skill(#{@skill.name}).meets_prerequisites?(): prereqs = #{@skill.prereqs}"
		if @skill.prereqs == nil
			return true
		end
		if build == nil
			build = @character.build if @character != nil
		end

		if @skill.prereqs.is_a? String
			return self.meets_prereq?(build, @skill.prereqs)
		end
		if @skill.prereqs.is_a? Array
			@skill.prereqs.each do |prereq|
				#puts "Character_Skill(#{@skill.name}).meets_prerequisites?(): prereq = #{prereq}"
				if !self.meets_prereq?(build, prereq)
					puts "Character_Skill(#{@skill.name}).meets_prerequisites?() Prereq #{prereq} not met..."
					return false
				end
			end
			return true
		end
		if @skill.prereqs.is_a? Hash
			if @skill.name != "Critical Slay/Parry" and  @skill.name != "Master Critical Slay/Parry" and @skill.name != "Assassinate/Dodge"
				return true
			end
			prof_count = build.count("Proficiency", @options )
			slay_count = build.count("Critical Slay/Parry", @options )
			mprof_count= build.count_mprofs( @options )
			mslay_count= build.count_mslays( @options )
			bstab_count= build.count("Backstab", @options )
			dodge_count= build.count("Assassinate/Dodge", @options)
			
			count =  prof_count - slay_count * 2
			mcount = mprof_count - mslay_count * 2
			bcount = bstab_count - dodge_count * 2

			if @skill.name == "Critical Slay/Parry"
				return count + mcount >= my_count * 2
			end
			if @skill.name == "Master Critical Slay/Parry"
				if count <= 0
					return count + mcount >= my_count * 2
				else
					return mcount >= my_count * 2
				end
			end
			if @skill.name == "Assassinate/Dodge"
				return bcount >= my_count * 2
			end
		end
	end

	def meets_prereq? build, prereq
		#puts "Character_Skill(#{@skill.name}).meets_prereq?(#{prereq})"
		found = false
		if prereq.match /\w* \d/
			return build.spell(prereq) > 0
		end
		build.skills.each do |check|
			#puts "Character_Skill(#{@skill.name}).meets_prereq?(#{prereq}): Checking #{check.skill.name}"
			if check.is_a?(Character_Skill) and check.fulfills_prereq?(prereq)
				found = true
				break
			end
		end
		if !found
			return false
		end
		return true
	end

end

