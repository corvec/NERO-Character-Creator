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

require 'yaml'

require 'nero_skills.rb'
require 'character_skill.rb'


class Build
	attr_reader :add_error

	def initialize(character, filename = nil)
		@character = character
		@skills = []
		@spells = {}
		@spells['Earth'] = [0] * 9
		@spells['Celestial'] = [0] * 9
		@spells['Nature'] = [0] * 9
		@needs_commit = true
		if filename != nil
			self.load YAML.load(File.new(filename))['Build']
		end
	end

	# Fill with skills from a provided YAML structure
	def load yaml_data
		@skills = []

		if yaml_data.is_a? Hash and yaml_data.has_key? 'Build'
			yaml_data = yaml_data['Build']
		end

		if yaml_data.nil?
			return
		end
		yaml_data.each do |skill|
			if skill.is_a? String
				self.add_skill skill, {}, 1, true
			elsif skill.is_a? Hash
				skill.each do |skill_name, props|
					properties = props.clone
					count = props['Count']
					properties.delete 'Count'
					self.add_skill skill_name, properties, count, true
				end
			end
		end
	end

	# Returns the set of skills that are not spells
	def skills
		result = []
		@skills.each do |skill|
			result << skill unless skill.skill.spell
		end

		return result
	end

	##########################################################################################
	####### SPELL TREE
	##########################################################################################

	def set_spell( spell, amount )
		spell = spell.to_s
		$log.info "Build.set_spell(#{spell.inspect},#{amount.inspect})"
		@spells[spell.split(' ')[0]][spell.split(' ')[1].to_i - 1] = amount
		$log.debug "Build.set_spell() = #{self.spell(spell).inspect}"
	end

	def spell spell
		val = spell_at(spell.to_s.split(' ')[0],spell.to_s.split(' ')[1].to_i)
		$log.debug "Build.spell(#{spell.inspect}) = #{val.inspect}"
		return val
	end

	def spell_at school, level
		if !@spells.has_key?(school) or !(level.is_a? Integer) or (@spells[school].length < level) or (level < 1)
			$log.warn "Build.spell_at(#{school.inspect},#{level.inspect}) = nil"
			return 0
		end
		#$log.debug "Build::spell_at(#{school.inspect},#{level.inspect}) = #{@spells[school][level - 1].inspect}"
		@spells[school][level - 1]
	end

	def spell_tree school
		@spells[school]
	end

	# Increase the number of spell slots in the given school at the given level by 1
	def increment_spell_slots school, lvl
		$log.info "Build::increment_spell_slots(#{school},#{lvl})"
		build_state_data = self.save_state
		if self.can_add_spells(school)
			set_spells_at(school, lvl, spells_at(school, lvl) + 1)
			enforce_legality(school, lvl)
			enforce_legality(school, lvl)
			self.legalize()
			if $config.setting('Enforce Build') and (self.calculate_cost() > @character.experience.build)
				@add_error = "Insufficient loose build."
				self.load_state(build_state_data)
				return false
			end
			return true
		else
			$log.error 'Cannot add spell: Missing some prerequisite.'
			@add_error = 'Cannot add spell: Missing some prerequisite.'
			return false
		end
	end

	# Decrease the number of spell slots in the given school at the given level by 1
	def decrement_spell_slots school, lvl
		set_spells_at(school, lvl, spells_at(school, lvl) - 1)
		enforce_legality(school, lvl)
		self.legalize()
		return true
	end

	def spells_at school, level
		spell_at school, level + 1
	end

	def set_spells_at school, level, count
		if count.is_a? Integer and count >= 0
			@spells[school][level] = count
		end
	end

	# Returns true if the character has the proper skills needed
	# to add spells.
	def can_add_spells school
		skill = NERO_Skill.lookup( "#{school} 1" )
		cskill= Character_Skill.new(skill, {}, 1, $character)

		if cskill.meets_prerequisites?
			return true
		elsif $config.setting('Satisfy Prerequisites')
			return self.automatically_add_prerequisites(skill, {}, 1)
		end
	end

	# Force the tree to be legal, keeping static the second parameter (the level)
	def enforce_legality school, static
		# First traverse down in number:
		(static - 1).downto(0) do |i|
			# turning 44 into 45 -> 55
			if spells_at(school,i) < spells_at(school,i+1)
				set_spells_at(school,i, spells_at(school,i+1))
			end
			if spells_at(school,i) < 4 and spells_at(school,i) == spells_at(school,i+1)
				set_spells_at(school,i, spells_at(school,i)+1)
			end
			if spells_at(school,i) <= 4 and spells_at(school,i) > spells_at(school,i+1)+2
				set_spells_at(school,i, spells_at(school,i)-1)
			end
			if spells_at(school,i) > 4 and spells_at(school,i) > spells_at(school,i+1)+1
				set_spells_at(school,i, spells_at(school,i)-1)
			end
		end
		(static + 1).upto(8) do |i|
			if spells_at(school,i-1) < spells_at(school,i)
				set_spells_at(school,i, spells_at(school,i-1))
			end
			if spells_at(school,i-1) < 4 and spells_at(school,i-1) == spells_at(school,i)
				set_spells_at(school,i, spells_at(school,i)-1)
			end
			if spells_at(school,i-1) <= 4 and spells_at(school,i-1) > spells_at(school,i) + 2
				set_spells_at(school,i, spells_at(school,i-1)-2)
			end
			if spells_at(school,i-1) > 4 and spells_at(school,i-1) > spells_at(school,i) + 1
				set_spells_at(school,i,spells_at(school,i-1)-1)
			end
		end
	end

	def spells_cost school, tree = nil
		tree = @spells[school] if tree == nil
		cost = 0
		(0..8).each do |i|
			cost += spell_cost(i) * tree[i]
		end
		return cost
	end

	def tree_cost school, tree = nil
		val = spells_cost(school,tree)
		return val if school == $character.primary
		return val * 2
	end

	# Returns the cost of a spell slot of a particular level for this character
	def spell_cost i
		case @character.character_class.to_s
		when 'Scholar'
			return (i * 1/2 + 1)
		when 'Templar'
			return (i * 2/3 + 1)
		when 'Fighter'
			return (i * 1/2 + 1)*3
		when 'Rogue'
			return (i * 1/2 + 1)*2
		else
			return (i * 1/2 + 1)
		end
	end

	# Forces an empty tree if the prereqs are not purchased
	def legalize_spell_tree()
		@spells['Earth'] = [0] * 9 if self.count('Healing Arts') <= 0
		@spells['Celestial'] = [0] * 9 if self.count('Read Magic') <= 0
		@spells['Nature'] = [0] * 9 if self.count('Runes of Nature') <= 0
	end

	# Returns true if the spells that the characters has are all legal
	# Returns false if any of them are illegal
	def legal_tree?
		if @spells['Earth'][0] > 0 and self.count('Healing Arts') <= 0
			return false
		end
		if @spells['Celestial'][0] > 0 and self.count('Read Magic') <= 0
			return false
		end
		if @spells['Nature'][0] > 0 and self.count('Runes of Nature') <= 0
			return false
		end
		return true
	end

	##########################################################################################
	####### END SPELL TREE
	##########################################################################################

	# directly converts this to a YAML string
	def to_s
		s = "Build:\n"
		@skills.each do |skill|
			s << "   - #{skill.to_s}"
			if skill.skill.limit != 1 or skill.skill.options.length > 0
				s << ":\n"
				if skill.skill.limit != 1
					s << "      Count: #{skill.count}\n"
				end
				skill.options.each do |o,v|
					s << "      #{o}: #{v}\n"
				end
			else
				s << "\n"
			end
		end
		@spells.each do |school, tree|
			next if tree[0] <= 0
			tree.each_with_index do |spell_amount, level|
				break if spell_amount <= 0
				s << "   - #{school} #{level + 1}:\n"
				s << "      Count: #{spell_amount}\n"
			end

		end
			
		return s
	end

	# converts this into a structure that, when dumped by YAML, will be the same as the string above
	def export
		data = []
		@skills.each do |skill|
			if skill.skill.limit != 1 or skill.skill.options.length > 0
				val = {skill.to_s => {}}
				if skill.skill.limit != 1
					val[skill.to_s]['Count'] = skill.count
				end
				skill.options.each do |o,v|
					val[skill.to_s][o] = v
				end
				data << val
			else
				data << skill.to_s
			end
		end
		@spells.each do |school, tree|
			next if tree[0] <= 0
			tree.each_with_index do |spell_amount, level|
				break if spell_amount <= 0
				skill_name = "#{school} #{level + 1}"
				val = {skill_name => {}}
				val[skill_name]['Count'] = spell_amount
				data << val
			end
		end
			
		return data
	end

	def calculate_cost
      self.cost()
	end

	def cost
		c = 0
		@skills.each do |skill|
			c += skill.cost
		end
		c +=     self.spells_cost(@character.primary)
		c += 2 * self.spells_cost(@character.secondary)
		return c
	end

	# Add a skill
	# If there is an error, store the error message in @add_error
	def add_skill(skill, options={}, amount=1, force=false)
		$log.debug "Build.add_skill(#{skill.inspect},#{options.inspect},#{amount.inspect},#{force})"
		@add_error = "No error occurred..."
		@auto_add_error = ''
		unless force
			build_data = self.save_state
		end

		unless skill.is_a? NERO_Skill
			skill = NERO_Skill.lookup(skill)
		end

		$log.debug "Build.add_skill(#{skill.inspect},#{options.inspect},#{amount.inspect},#{force.inspect}) - Lookup completed."

		unless skill.is_a? NERO_Skill
			$log.error "Build.add_skill(#{skill.inspect}) - Skill was not found in the lookup table."
			@add_error = "Skill is not a NERO Skill."
			return false
		end

		# Skill is a spell
		if skill.spell
			return self.set_spell(skill, amount) if force
			if amount != 1
				@add_error = "Build.add_skill(#{skill.to_s.inspect}) - Cannot add spells through this dialog"
				return false
			end
			school = skill.to_s.split(' ')[0]
			lvl = skill.to_s.split(' ')[1].to_i
			return self.increment_spell_slots(school, lvl-1)
		end

		unless options.is_a? Hash
			options = parse_options(options,skill.to_s)
		end

		$log.debug "Build.add_skill(#{skill.to_s.inspect}) - Skill requires #{skill.options.length} options"

		if options.length < skill.options.length
			$log.warn "Build.add_skill(#{skill.to_s.inspect}) - Insufficient options provided..."
			@add_error = "Insufficient options provided: Please provide the following options: |"
			skill.options.each do |o|
				@add_error += " #{o} |"
			end
			return false
		end

		char_skill = Character_Skill.new skill, options, amount, @character

		if char_skill.cost == false
			@add_error = "You cannot add #{skill.to_s} because it does not have a cost defined for your character.  It is most likely a racial ability."
			if char_skill.to_s.match "Master Critical Attack" or char_skill.to_s.match 'Proficiency'
  				@add_error = "You cannot have a Master Critical Attack and a Proficiency in the same hand.  Upgrade your existing skill to a Master Proficiency instead."
			end
			$log.warn "Build.add_skill(#{skill.to_s.inspect}): Cost undefined."
			return false
		end

		unless force
			unless char_skill.meets_prerequisites?(self)
				$log.warn "Build.add_skill(#{skill.to_s.inspect}): Prerequisites not met"
				# Generate the error either way, in case the operation fails down the road: the user
				# needs to know about the prerequisites
				if $config.setting('Satisfy Prerequisites')
					prereq_skills_added = self.automatically_add_prerequisites(skill,options,amount)
					unless prereq_skills_added
						@add_error = "Encountered an error during an #{@auto_add_error}"
						self.load_state build_data
						return false
					end
				else
					@add_error = "You cannot add '#{skill.to_s}' because you are missing some prerequisite.  The prerequisites are: |"
					spreqs = skill.prereqs.to_a
					spreqs.each do |prereq|
						if prereq.is_a? Array
							@add_error += "#{prereq[0]}x#{prereq[1]}"
						else
							@add_error += " #{prereq} |"
						end
						@add_error += ', ' unless spreqs.last == prereq
						@add_error += ']' if spreqs.last == prereq
					end
					return false
				end
			end
			@skills.each do |skill_to_check|
				if char_skill.is_included_in?(skill_to_check.skill)
					$log.warn "Build.add_skill(#{skill.to_s.inspect}): Skill included in #{skill_to_check.to_s.inspect}"
					@add_error = "You cannot add '#{skill.to_s}' because it is included in #{skill_to_check.to_s}, which you already have."
					return false
				end
			end
		end


		force_add_skill(char_skill,force)
		
		# Check its includes and if they're present, delete them
		unless force
			self.delete_includes(skill,options)
		end

		# Enforce Build Total:
		if !force and $config.setting('Enforce Build') and (self.calculate_cost() > @character.experience.build)
			$log.warn "Build.add_skill(#{skill.to_s.inspect}): Not enough loose build."
			@add_error = "You cannot add #{skill.to_s} because you do not have enough loose build!  You must have #{self.calculate_cost} total build to purchase this skill."
			@add_error += "\nThis followed a successful #{@auto_add_error}\nAutomatically purchased skills have been removed." unless @auto_add_error.empty?
			self.load_state build_data
			@needs_commit = true
			return false
		end


		return true
	end



	def automatically_add_prerequisites skill, options={}, count=1
		if skill.is_a? Character_Skill
			char_skill = skill
			skill   = char_skill.skill
			count   = char_skill.count
			options = char_skill.options
		else
			char_skill = Character_Skill.new(skill,options,count,@character)
		end

		auto_add_error = "attempt to automatically add prerequisites for '#{skill.to_s}'.  The prerequisites are: ["
		$log.info "Build.add_skill(#{skill.to_s.inspect}): Automatically purchasing prerequisites"
		error_encountered = false

		enforce_build_value = $config.setting('Enforce Build')
		$config.update_setting('Enforce Build',false)

		spreqs = skill.prereqs.to_a

		spreqs.each do |prereq|
			if prereq.is_a? Array
				auto_add_error += "#{prereq[0]}x#{prereq[1]}"
				unless error_encountered
					(prereq[1]*count).times do
						unless char_skill.meets_prerequisites? self
							unless self.add_skill(prereq[0],options,1)
								error_encountered = true
							end
						end
					end
				end
			else # prereq.is_a String
				auto_add_error += prereq
				unless error_encountered
					unless self.add_skill(prereq,options,1)
						error_encountered = true
					end
				end
			end
			unless spreqs.last == prereq
				auto_add_error += ', '
			else
				auto_add_error += ']'
			end
		end
		$log.info "AAE: #{auto_add_error}"
		$config.update_setting('Enforce Build',enforce_build_value)
		@auto_add_error = auto_add_error
		if error_encountered
			return false
		end
		@needs_commit = true
		return true
	end

	# Save the current build in a temporary variable
	def save_state
		skills_clone = []
		@skills.each do |skill|
			skills_clone << skill.clone
		end
		spells_clone = {}
		@spells.each do |school,tree|
			spells_clone[school] = tree.clone
		end
		return [skills_clone, spells_clone]
	end

	# Load the current build from the temporary variable, if the temp variable is set
	def load_state data
		skills_clone = data[0]
		spells_clone = data[1]
		unless skills_clone.nil?
			@skills = skills_clone
			spells_clone.each do |school, tree|
				@spells[school] = tree
			end
		end
	end


	# Returns the cost currently spent upon the skills included by the listed skill
	def includes_cost nero_skill
		$log.debug "Build.includes_cost(#{nero_skill.to_s.inspect})"
		includes = nero_skill.get_all_includes()

		cskills = self.find_skills(includes)

		cost = 0
		cskills.each do |cskill|
			cost += cskill.cost
		end
		$log.debug "Build.includes_cost(#{nero_skill.to_s.inspect}) = #{cost.inspect}"
		return cost
	end

	# Returns a list of character skills
	def find_skills skills
		$log.debug "Build.find_skills(#{skills.inspect})"
		skill_list = []
		if skills.is_a? Hash
			skills.each do |skill,ranks|
				temp_cskill = self.lookup(skill)
				next if temp_cskill.nil?
				nskill = NERO_Skill.lookup(skill)
				cskill = Character_Skill.new(nskill, temp_cskill.options, ranks, @character)
				skill_list << cskill unless cskill.nil?
			end
			return skill_list
		end
		if skills.is_a? Array
			skills.each do |skill|
				cskill = self.lookup(skill)
				skill_list << cskill unless cskill.nil?
			end
			return skill_list
		end
		if skills.is_a? String
			skill = skills
			cskill = self.lookup(skill)
			skill_list << cskill unless cskill.nil?
			return skill_list
		end
	end

	def lookup skill, options = {}
		$log.debug "Build.lookup(#{skill.inspect},{#{options.inspect}.inspect})"
		@skills.each do |cskill|
			if cskill.skill.to_s == skill
				match = true
				options.each do |o,v|
					match = false if cskill.options[o] != v
				end
				return cskill if match
			end
		end
		return nil
	end

	# Indicates whether or not the build has changed since this was last called
	def commit?
		temp = @needs_commit
		@needs_commit = false

		$log.debug "Build.commit?() = #{temp.inspect}"
		return temp
	end

	def delete_includes nero_skill, options
		$log.info "Build.delete_includes(#{nero_skill.to_s.inspect}, #{options.inspect})"

		includes = nero_skill.get_all_includes()
		if includes.is_a? Array
			included_skills = self.find_skills(includes)
		elsif includes.is_a? Hash
			included_skills = self.find_skills(includes.keys)
		end
		included_skills.each do |inc_skill|
			if includes.is_a? Array
				self.delete_skill(inc_skill.to_s, options, inc_skill.count)
			elsif includes.is_a? Hash
				self.delete_skill(inc_skill.to_s, options, includes[inc_skill.to_s])
			end
		end
		return true
	end

	def old_delete_includes skill, options, i=0
		$log.info "Build.delete_includes(#{skill.to_s.inspect}, {#{options.inspect}}, #{i})"
		return if i > 5

		
		if skill.includes.is_a? Array
			$log.info "delete_includes: includes = #{skill.includes.inspect}"
			skill.includes.each do |inc_skill|
				if inc_skill.is_a? String
					self.delete_skill inc_skill, options
					rec_skill =  NERO_Skill.lookup(inc_skill)
					self.delete_includes(rec_skill, options, i+1) if rec_skill.is_a? NERO_Skill
				end
			end
		elsif skill.includes.is_a? Hash
			$log.info "delete_includes: includes = #{skill.includes.inspect}"
			skill.includes.each do |inc_skill, inc_ranks|
				if inc_skill.is_a? String
					if self.delete_skill inc_skill, options, inc_ranks
						break
					end
				end
			end
		else
			$log.error "skill.includes in an unusable format!"
			return false
		end
	end

	def weapon_hash
		wh = {'Archery'=>['Bow','Crossbow'],
			'One Handed Blunt'=>['Sap','Bludgeon','Short Hammer','Long Hammer','Short Mace','Long Mace'],
			'One Handed Edged'=>['Dagger','Hatchet','Short Sword','Long Sword','Short Axe','Long Axe'],
			'Polearm'=>['Polearm'],#'Two Handed Axe','Halberd','Scythe','Bardiche','Guisarme','Glaive'],
			'Small Weapon'=>['Sap','Bludgeon','Dagger','Hatchet','Small Hammer'],
			'Staff'=>['Staff'],
			'Thrown Weapon'=>['Throwing Dagger','Javelin','Throwing Rock'],
			'Two Handed Blunt'=>['Two Handed Blunt'],
			'Two Handed Sword'=>['Two Handed Sword']}
		wh['One Handed Weapon Master'] = wh['One Handed Edged'] + wh['One Handed Blunt']
		wh['Two Handed Weapon Master'] = wh['Polearm'] + wh['Two Handed Blunt'] + wh['Two Handed Sword']
		wh['Weapon Master'] = wh['One Handed Weapon Master'] + wh['Two Handed Weapon Master']
		return wh
	end

	def valid_option_values option
		case option
		when 'Hand'
			['Right','Left']
		when 'Weapon'
			wh = self.weapon_hash

			r = ['Other']
			@skills.each do |s|
				r += wh[s.skill.to_s] if wh.has_key?(s.skill.to_s)
			end
			return r
		else
			nil
		end
	end

	# Intended to be used by add_skill upon finding includes
	# Does NOT check to ensure that the removed skill is not
	# satisfying other requirements; for that, run build.legal?() or build.legally_delete_skill
	def delete_skill skill, options = {}, ranks = 1
		$log.info "Build.delete_skill(#{skill.inspect},#{options.inspect},#{ranks.inspect})"
		$log.debug("Build.delete_skill() - @needs_commit = true")
		@needs_commit = true
		@skills.each do |cskill|
			if cskill.skill.to_s == skill
				match = true
				options.each do |o,v|
					if cskill.options[o] != v
						match = false
					end
				end
				if match
					if cskill.count > ranks and ranks != 0
						cskill.count= cskill.count - ranks
						$log.info "Build.delete_skill(#{skill.inspect}) - #{ranks} rank(s) removed"
					else
						@skills.delete cskill
						$log.info "Build.delete_skill(#{skill.inspect}) - Skill deleted"
					end
					break
				end
			end
		end
	end

	def legally_delete_skill skill, options = {}, ranks = 1
		$log.info "Build::legally_delete_skill(#{skill.inspect})"
		temp = @needs_commit
		self.delete_skill skill, options, ranks
		unless temp or self.count(skill, options) == 0
			@needs_commit = false 
			$log.debug("Build.legally_delete_skill() - @needs_commit = false")
		end

		self.legalize
	end

	# While this build is not legal, delete any skill that is illegal
	# If the character does not have spell prereqs, delete the spells
	def legalize
		$log.info "Build::legalize()"
		domino = false
		while !self.legal?
			skills_to_delete = self.illegal_skills()
			skills_to_delete.each do |skill|
				$log.warn "Build::legalize() - Deleting #{skill.inspect}"
				domino = true
				self.delete_skill skill
			end
			self.legalize_spell_tree()
		end
		$log.debug "Build::legalize() - Domino: #{domino.inspect}"
		return domino
	end

	# Returns true if the character's build is legal
	def legal?
		@skills.each do |s|
			if !s.meets_prerequisites?(self, 0) or s.cost == false
				$log.debug "Build not legal.  #{s.skill.inspect} does not meet its prerequisites or is prohibited."
				return false
			end
		end
		return self.legal_tree?
	end


	def illegal_skills
		skills = []
		@skills.each do |s|
			if !s.meets_prerequisites?(self, 0) or s.cost == false
				skills << s.skill.to_s
			end
		end
		return skills
	end


	def count skill, options = {}
		count = 0
		@skills.each do |cskill|
			if cskill.to_s == skill
				options_match = true
				options.each do |o,v|
					if cskill.options[o] != v
						options_match = false
					end
				end
				if options_match
					count += cskill.count
				end
			end
		end
		return count
	end

	# Counts master profs in the passed hand
	def count_mprofs options
		o = options.clone
		o.delete 'Weapon'
		return self.count('Master Proficiency',o)
	end

	# Counts master slays in the given hand
	def count_mslays options
		o = options.clone
		o.delete 'Weapon'
		return self.count('Master Critical Slay/Parry',o)
	end

	# Counts two handed melee weapon profs
	# Returns 0 if the player does not have any
	# Returns -1 if the player does not have the skill to use one
	# Note that the options parameter is for uniformity and is not used
	def count_2hprofs options=nil
		# Check to see if the character has skill in a two handed weapon:
		count = -1
		self.skills.each do |check|
			if check.is_a?(Character_Skill) and check.fulfills_prereq?('Two Handed Weapon')
				count = 0
				break
			end
		end

		if count == -1
			$log.debug("Build.count_2hprofs() returning -1")
			return -1
		end
		count = 0
		count += self.count('Master Proficiency')


		weapons = self.weapon_hash['Two Handed Weapon Master']

		count += self.count('Proficiency',{'Weapon'=>'Polearm'})
		count += self.count('Proficiency',{'Weapon'=>'Staff'})
		count += self.count('Proficiency',{'Weapon'=>'Two Handed Sword'})
		count += self.count('Proficiency',{'Weapon'=>'Two Handed Blunt'})

		$log.debug("Build.count_2hprofs() returning #{count}")

		return count
	end

private
	def force_add_skill(char_skill, force)
		$log.debug("Build.force_add_skill(Character_Skill(#{char_skill.to_s.inspect},#{char_skill.count.inspect},#{char_skill.options.inspect}),#{force.inspect})")
		if self.count(char_skill.to_s, char_skill.options) > 0
			$log.info "Build.force_add_skill(#{char_skill.to_s.inspect}): Increasing existing skill to #{char_skill.count + self.count(char_skill.to_s, char_skill.options)}"
			@skills.each do |s|
				if s.to_s == char_skill.to_s
					options_match = true
					if char_skill.options != nil
						char_skill.options.each do |o,v|
							if s.options[o] != v
								options_match = false
							end
						end
					end
					if options_match
						s.count = s.count + char_skill.count
						break
					end
				end
			end
		else
			$log.info "Build.force_add_skill(#{char_skill.to_s.inspect},#{char_skill.count}): Adding new skill"
			@needs_commit = true
			$log.debug("Build.force_add_skill() - @needs_commit = true")
			char_skill.actualize()
			@skills << char_skill
		end
	end

	def parse_options(options, skill_name)
		results = {}

		os = options.split(',')
		os.each do |option|
			option.strip!
			if ['Proficiency','Critical Attack','Critical Slay/Parry'].include? skill_name
				if option.downcase.include? 'right'
					results['Hand'] = 'Right'
				elsif option.downcase.include? 'left'
					results['Hand'] = 'Left'
				else
					options = options.gsub /Weapon.*[^A-Za-z]/, ''
					results['Weapon'] = option
				end
			elsif skill_name == 'Craftsman Other'
				results['Type'] = option
			elsif ['Master Proficiency','Master Critical Attack','Master Critical Slay/Parry','Backstab','Back Attack','Assassinate/Dodge'].include? skill_name
				if option.downcase.include? 'right'
					results['Hand'] = 'Right'
				elsif option.downcase.include? 'left'
					results['Hand'] = 'Left'
				end
			end
		end

		$log.debug "Build.parse_options('#{options.inspect}','#{skill_name.inspect}') return length = #{results.length}"

		return results
	end

end


# Localized Testing
if __FILE__ == $0
	$log = Logger.new('build.log',10,102400)
	$log.info "Testing build.rb"

	NERO_Skills.add_skills 'data/skills.yml'


	b = Build.new 'test.yml'
	b.calculate_cost
	$log.info b.count('One Handed Edged', {})
	b.add_skill("One Handed Edged")
	o = {'Hand' => 'Left','Weapon' => 'Short Sword'}
	b.add_skill("Proficiency",o)
	b.add_skill("Proficiency",o,1)
	o2 = {'Hand' => 'Right','Weapon' => 'Long Sword'}
	b.add_skill("Proficiency",o2)
	b.add_skill("Master Proficiency",o)
	b.add_skill("Florentine")
	b.add_skill("Two Weapons")
	b.add_skill("Style Master")
	b.add_skill("Shield")
	$log.info "Prof Count: #{b.count('Proficiency',o)}"
	b.add_skill("Critical Slay/Parry",o, 1)
	b.add_skill("Alchemy",nil, 1)
	$log.info b.to_s
	$log.info "Total Cost for a Barbarian Fighter: #{b.calculate_cost 'Fighter','Barbarian','Nature'}"

	require 'irb'
	require 'irb/completion'
	IRB.start
end
