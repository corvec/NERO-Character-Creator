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
		$log.debug "Character_Skill.new(#{nero_skill.inspect},#{options.inspect},#{amount.inspect})"
		if amount.is_a? Integer
			@count = nero_skill.apply_limit(amount)
		else
			@count = 1
		end
		#Debug message:
		if @count != amount.to_i
			$log.warn "Character_Skill.new(): Limited amount to #{@count}"
		end
		@character = character
		@temp = true
	end

	# Set the number of this skill to the passed amount.
	def count= amount
		if amount.to_i > 0
			@count = @skill.apply_limit(amount)
		end
	end

	# Returns the name of this skill
	def name
		@skill.to_s
	end

	def to_s
		@skill.to_s
	end

	def actualize
		@temp = false
	end


	# Returns true if the character can legally have this skill,
	# given racial prohibitions but not account for prerequisites
	# or build.
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

	def cost class_name=nil, race=nil, primary_school=nil, build=nil
		if $character.race.skills.keys.include? @skill.to_s
			return $character.race.skills[@skill.to_s] * @count
		end

		cost = base_cost(class_name,race,primary_school,build)
		if cost == false
			return false
		end


		return cost
	end

	# Returns the cost of this skill
	# Accounts for the primary school of the character with spells
	# Accounts for templar profs
	# Accounts for critical attacks if passed a reference to the character's build
	def base_cost class_name = nil, race = nil, primary_school=nil, build=nil
		if @character != nil
			class_name     = @character.character_class.to_s if class_name     == nil
			race           = @character.race.to_s            if race           == nil
			primary_school = @character.primary              if primary_school == nil
			secondary_school=@character.secondary            if secondary_school==nil
			build          = @character.build                if build          == nil
		end

		if !self.legal?
			return false
		end

		cost = @skill.cost(class_name, race)

		# Prohibited or racial
		if cost == nil or @character.race.prohibited? @skill
			return false
		end

		modifiers = $character.race.skill_cost_modifiers(@skill.to_s)

		if cost.is_a? Integer
			cost *= 2 if modifiers.include? :doubled
			cost = (cost/2) + (cost%2) if modifiers.include? :halved
			cost = cost - 1 if modifiers.include? :reduced

			return @count * cost
		end
		# Formal
		unless @skill.to_s.match('Formal').nil?
			$log.info "Character_Skill.cost() Calculating cost of Formal Magic"
			if @skill.to_s.match(primary_school)
				cost = cost['Primary']

				cost *= 2 if modifiers.include? :doubled
				cost = (cost/2) + (cost%2) if modifiers.include? :halved
				cost = cost - 1 if modifiers.include? :reduced

				return @count * cost
			elsif @skill.to_s.match(secondary_school)
				cost = cost['Secondary']

				cost *= 2 if modifiers.include? :doubled
				cost = (cost/2) + (cost%2) if modifiers.include? :halved
				cost = cost - 1 if modifiers.include? :reduced

				return @count * cost
			else
				$log.error "School of formal magic did not match primary OR secondary"
				return false
			end
		end

		# Must be a templar purchasing profs or crit attacks
		# (or a rogue getting master profs / master crit attacks)
		# TODO: check build to see if there are profs if this is a crit att
		unless @skill.to_s.match('Attack').nil?
			set = 0
			if build != nil
				unless @skill.to_s.match('Master').nil?
					set = build.count('Master Proficiency', {}) + build.count('Proficiency',{})
					set = 2 if set > 2
					# You cannot buy Master Critical Attacks if you already have normal Proficiencies
					# I'm allowing it unless it's the same hand
					if build.count('Proficiency', {'Hand'=>@options['Hand']}) != 0
						return false
					end
				else
					set = build.count('Proficiency', {}) + build.count('Master Proficiency', {})
					set = 2 if set > 2
				end
			end
			return @count * cost[set]
		end
		# Must be a prof.
		# Profs are accounted for in the following order:
		# Right, Master; Left, Master; Right, Normal; Left, Normal
		# Technically there's a bug here: a templar purchasing different normal profs in the same hand will pay weird prices
		# He's saving 2 build over buying a single Master Prof...
		additional_count = 0
		unless @skill.to_s.match('Master') and @options['Hand'] == 'Right'
			additional_count += build.count('Master Proficiency',{'Hand'=>'Right'})
			unless @skill.to_s.match('Master') and @options['Hand'] == 'Left'
				additional_count += build.count('Master Proficiency',{'Hand'=>'Left'})
				unless (not @skill.to_s.match('Master')) and @options['Hand'] == 'Right'
					additional_count += build.count('Proficiency',{'Hand'=>'Right'})
					unless (not @skill.to_s.match('Master')) and @options['Hand'] == 'Left'
						additional_count += build.count('Proficiency',{'Hand'=>' Left'})
					end
				end
			end
		end

		# Prevent addition of a normal Prof if you have a Master Crit Attack in that hand
		unless skill.to_s.match('Master')
			if build.count('Master Critical Attack', {'Hand'=>@options['Hand']}) > 0
				return false
			end
		end

		# Use additional count to determine the first cost to apply
		# Use count to determine the final cost to apply
		if additional_count >= 2
			return cost[2]*@count
		end
		if additional_count == 1
			return cost[1] + cost[2]*(@count-1)
		end
		if @count >= 3
			return cost[0] + cost[1] + (cost[2]*(@count-2))
		end
		if @count == 2
			return cost[0] + cost[1]
		end
		return cost[0]

		# The following occurs when calculating the cost of a solitary temporary prof
		if build != nil and @temp
			if @skill.to_s.match('Master')
				set = build.count('Master Proficiency', {})
				set = 2 if set > 2
			else
				set = build.count('Proficiency', {})
				set = 2 if set > 2
			end
			return cost[set]
		end
		return cost[0]
	end

	# Returns true if the passed skill includes this one (recursive)
	def is_included_in?(skill)
		skill.includes.each do |inc|
			if inc.to_s == @skill.to_s
				skill_inc = NERO_Skill.lookup(inc)
				if !skill_inc.is_a? NERO_Skill
					next
				end
				if skill_inc.limit == 1
					return true
				else
					next
				end
			end
			recurse = NERO_Skill.lookup(inc)
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
		$log.debug "Character_Skill(#{@skill.to_s}).fulfills_prereq(#{prereq})"

		if @skill.to_s == prereq
			return check_prereq_count(count)
		end

		# Check to see if it or any of the includes match it
		@skill.includes.each do |inc|
			if inc.to_s == prereq
				temp = check_prereq_count(count)
				return temp
			end
			recurse = NERO_Skill.lookup(inc)
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
			$log.debug "Character_Skill(#{@skill.to_s}).check_prereq_count() : returning true"
			return true
		end
		$log.info "Character_Skill(#{@skill.to_s}).check_prereq_count() : returning #{count - @count}"
		return count - @count
	end

	# Returns true if the prereqs of this skill are fulfilled by
	# the existing build.
	# This also checks to ensure that skills such as Slays
	# are at a legal total amount, given the amount of proficiencies
	def meets_prerequisites? build = nil, my_count = @count
		$log.debug "Character_Skill(#{@skill.to_s}).meets_prerequisites?(): prereqs = #{@skill.prereqs}"
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
				$log.debug "Character_Skill(#{@skill.to_s}).meets_prerequisites?(): prereq = #{prereq}"
				if !self.meets_prereq?(build, prereq)
					$log.info "Character_Skill(#{@skill.to_s}).meets_prerequisites?() Prereq #{prereq} not met..."
					return false
				end
			end
			return true
		end
		if @skill.prereqs.is_a? Hash
			if @skill.to_s != "Critical Slay/Parry" and  @skill.to_s != "Master Critical Slay/Parry" and @skill.to_s != "Assassinate/Dodge"
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

			if @skill.to_s == "Critical Slay/Parry"
				return count + mcount >= my_count * 2
			end
			if @skill.to_s == "Master Critical Slay/Parry"
				if count <= 0
					return count + mcount >= my_count * 2
				else
					return mcount >= my_count * 2
				end
			end
			if @skill.to_s == "Assassinate/Dodge"
				return bcount >= my_count * 2
			end
		end
	end

	def meets_prereq? build, prereq
		$log.debug "Character_Skill(#{@skill.to_s}).meets_prereq?(#{prereq})"
		found = false
		if prereq.match /\w* \d/
			return build.spell(prereq) > 0
		end
		build.skills.each do |check|
			$log.debug "Character_Skill(#{@skill.to_s}).meets_prereq?(#{prereq}): Checking #{check.skill.to_s}"
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


if __FILE__ == $0
	$log = Logger.new('build.log',20,102400)

	$log.info "Testing character_skill.rb"
	$log.warn "Nothing to test!"

end

