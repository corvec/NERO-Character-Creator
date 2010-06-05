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
	def initialize(character, filename = nil)
		@character = character
		@skills = []
		@spells = {}
		@spells['Earth'] = [0] * 9
		@spells['Celestial'] = [0] * 9
		@spells['Nature'] = [0] * 9
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
			result << skill unless skill.skill.is_a_spell?()
		end

		return result
	end

	##########################################################################################
	####### SPELL TREE
	##########################################################################################

	def set_spell( spell, amount )
		unless spell.is_a? String
			spell = spell.name
		end
		$log.info "Build::set_spell(#{spell},#{amount})"
		@spells[spell.split(' ')[0]][spell.split(' ')[1].to_i - 1] = amount
		$log.debug self.spell(spell)
	end

	def spell spell
		val = spell_at(spell.to_s.split(' ')[0],spell.to_s.split(' ')[1].to_i)
		$log.debug "Build::spell(#{spell}) = #{val}"
		return val
	end

	def spell_at school, level
		if !@spells.has_key?(school) or !(level.is_a? Integer) or (@spells[school].length < level) or (level < 1)
			$log.warn "Build::spell_at(#{school},#{level}) = nil"
			return 0
		end
		#$log.debug "Build::spell_at(#{school},#{level}) = #{@spells[school][level - 1]}"
		@spells[school][level - 1]
	end

	def spell_tree school
		@spells[school]
	end

	def set_tree school, tree
		$log.info "Build::set_tree(#{school},#{tree.join '/'})"
		tree.each_with_index do |spell_count, i|
			@spells[school][i] = spell_count
		end
		self.legalize()
	end

	def spells_cost school
		cost = 0
		(0..8).each do |i|
			cost += spell_cost(i) * @spells[school][i]
		end
		return cost
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

	# Returns true if the character can have ANY spells
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
			s << "   - #{skill.name}"
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
				val = {skill.name => {}}
				if skill.skill.limit != 1
					val[skill.name]['Count'] = skill.count
				end
				skill.options.each do |o,v|
					val[skill.name][o] = v
				end
				data << val
			else
				data << skill.name
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

	def get_add_error
		@add_error
	end

	# Add a skill
	# If there is an error, store the error message in @add_error
	def add_skill(skill, options={}, amount=1, force=false)
		$log.debug "Build.add_skill(#{skill.inspect},#{options.inspect},#{amount.inspect},#{force})"
		@add_error = "No error occurred..."
		unless skill.is_a? NERO_Skill
			skill = $nero_skills.lookup(skill)
		end

		unless skill.is_a? NERO_Skill
			@add_error = "Skill is not a NERO Skill."
			return false
		end

		if skill.is_a_spell?
			if force
				self.set_spell skill, amount
			end
			@add_error = "Cannot add spells through this dialog"
			return false
		end

		unless options.is_a? Hash
			options = parse_options(options,skill.name)
		end

		$log.debug "Skill #{skill.name} has #{skill.options.length} options"

		if options.length < skill.options.length
			$log.warn "Insufficient options provided..."
			@add_error = "Insufficient options provided: Please provide the following options: |"
			skill.options.each do |o|
				@add_error += " #{o} |"
			end
			return false
		end

		$log.debug "Build.add_skill(#{skill.inspect},#{options.inspect},#{amount.inspect},#{force})"

		char_skill = Character_Skill.new skill, options, amount, @character

		if char_skill.cost == false
			@add_error = "A cost is not defined for your character for this skill.  It is most likely a racial ability."
			return false
		end

		unless force
			unless char_skill.meets_prerequisites?(self)
				$log.warn "Build.add_skill(#{skill.name}): Prerequisites not met"
				@add_error = "Prerequisite(s) not met.  They are: |"
				skill.prereqs.each do |prereq|
					if prereq.is_a? Array
						@add_error += " #{prereq[0]}x#{prereq[1]} |"
					else
						@add_error += " #{prereq} |"
					end
				end
				return false
			end
			@skills.each do |skill_to_check|
				if char_skill.is_included_in?(skill_to_check.skill)
					$log.warn "Build.add_skill(#{skill.name}): Skill included in #{skill_to_check.name}"
					@add_error = "This skill is included in the skill #{skill_to_check.name}, which you already have."
					return false
				end
			end
		end


		force_add_skill(char_skill,force)


		# Check its includes and if they're present, delete them
		unless force
			self.delete_includes(skill,options)
		end
		return true
	end

	def delete_includes skill, options, i=0
		$log.info "delete_includes(#{skill.name}, #{options}, #{i})"
		return if i > 5

		
		# skill is a simple list for Style Master, 
		if skill.includes.is_a? Array
			$log.info "delete_includes: includes = #{skill.includes.join(',')}"
			skill.includes.each do |inc_skill|
				if inc_skill.is_a? String
					self.delete_skill inc_skill, options
					rec_skill =  $nero_skills.lookup(inc_skill)
					self.delete_includes(rec_skill, options, i+1) if rec_skill.is_a? NERO_Skill
				end
			end
		elsif skill.includes.is_a? Hash
			$log.info "delete_includes: includes = #{skill.includes.to_s}"
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

	# Intended to be used by add_skill upon finding includes
	# Does NOT check to ensure that the removed skill is not
	# satisfying other requirements; for that, run build.legal?() or build.legally_delete_skill
	def delete_skill skill, options = {}, ranks = 1
		$log.info "Build::delete_skill(#{skill},#{options},#{ranks})"
		@skills.each do |cskill|
			if cskill.skill.name == skill
				match = true
				options.each do |o,v|
					if cskill.options[o] != v
						match = false
					end
				end
				if match
					if cskill.count > ranks and ranks != 0
						cskill.count= cskill.count - ranks
						$log.info "Build.delete_skill(#{skill}) - #{ranks} rank(s) removed"
					else
						@skills.delete cskill
						$log.info "Build.delete_skill(#{skill}) - Skill deleted"
					end
					break
				end
			end
		end
	end

	def legally_delete_skill skill, options = {}, ranks = 1
		$log.info "Build::legally_delete_skill(#{skill})"
		self.delete_skill skill, options, ranks

		self.legalize
	end

	def legalize
		$log.info "Build::legalize()"
		domino = false
		while !self.legal?
			skills_to_delete = self.illegal_skills()
			skills_to_delete.each do |skill|
				$log.warn "Build::legalize() - Deleting #{skill}"
				domino = true
				self.delete_skill skill
			end
			self.legalize_spell_tree()
		end
		$log.debug "Build::legalize() - Domino: #{domino}"
		return domino
	end

	def legal?
		@skills.each do |s|
			if !s.meets_prerequisites?(self, 0) or s.cost == false
				$log.debug "Build not legal.  #{s.skill.name} does not meet its prerequisites or is prohibited."
				return false
			end
		end
		return self.legal_tree?
	end


	def illegal_skills
		skills = []
		@skills.each do |s|
			if !s.meets_prerequisites?(self, 0) or s.cost == false
				skills << s.skill.name
			end
		end
		return skills
	end


	def count skill, options = {}
		count = 0
		@skills.each do |cskill|
			if cskill.name == skill
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

	def count_mprofs options
		o = options.clone
		o.delete 'Weapon'
		return self.count('Master Proficiency',o)
	end

	def count_mslays options
		o = options.clone
		o.delete 'Weapon'
		return self.count('Master Critical Slay/Parry',o)
	end
private
	def force_add_skill(char_skill, force)
		if self.count(char_skill.name, char_skill.options) > 0
			$log.info "Build.force_add_skill(#{char_skill.name}): Increasing existing skill to #{char_skill.count + self.count(char_skill.name, char_skill.options)}"
			@skills.each do |s|
				if s.name == char_skill.name
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
			$log.info "Build.force_add_skill(#{char_skill.name},#{char_skill.count}): Adding new skill"
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

		$log.debug "Build.parse_options('#{options}','#{skill_name}') return length = #{results.length}"

		return results
	end

end


# Localized Testing
if __FILE__ == $0
	$log = Logger.new('build.log',10,102400)
	$log.info "Testing build.rb"

	$nero_skills = NERO_Skills.new 'data/skills.yml'


	b = Build.new 'test.yml'
	b.calculate_cost
	$log.info b.count('One Handed Edged', {})
	$b = b
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
