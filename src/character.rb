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

require 'experience.rb'
require 'build.rb'
require 'date'
require 'yaml'


# This regards the data on the Info screen
class NERO_Character
	attr_reader :player_name, :name, :date_created, :race, :subrace, :character_class
	attr_writer :player_name, :name, :date_created, :subrace, :backstory
	attr_reader :experience, :primary, :secondary, :backstory, :build, :spirit_effects, :body_effects
	def initialize(filename=nil)
		@player_name = ''
		@name = ''
		@date_created = Date.today
		@race = NERO_Race.new()
		@subrace = ''
		@character_class = NERO_Class.new()
		@primary = 'Earth'
		@secondary = 'Celestial'

		@death_history = Death_History.new
		@spirit_effects = Formal_Effects.new 'Spirit'
		@body_effects = Formal_Effects.new 'Body'

		@backstory = ''

		# References to other classes:
		@experience = Experience.new()
		@build = Build.new(self)

		if filename != nil
			self.load(filename)
		end
	end

	def primary= school
		if @secondary == school
			@secondary = @primary
		end
		@primary = school
	end

	def secondary= school
		if @primary == school
			@primary = @secondary
		end
		@secondary = school
	end

	def calculate_body
		body = 0
		case @character_class.name
		when 'Fighter'
			body = 2 * @experience.level + 4
		when 'Rogue'
			body = @experience.level + 3
		when 'Templar'
			body = @experience.level + 3
		when 'Scholar'
			body = @experience.level * (0.666667) + 3
		end

		case @race.race
		when 'Barbarian':
			body += 2
		when 'Half Orc':
			body += 2
		when 'Half Ogre':
			body += 2
		when 'Dwarf':
			body += 1
		when 'Elf':
			body -= 1
		when 'Hobling':
			body -= 1
		end
		return body
	end

	def character_class=( c_class )
		if @race.race == 'Hobling' and c_class == 'Fighter'
			return
		end
		@character_class.name= c_class
	end

	def race=( race )
		if @character_class.name == 'Fighter' and race == 'Hobling'
			return
		end
		@race.race= race
		@build.legalize
	end

	def build_spent()
		return @build.calculate_cost
	end

	#attr_reader :name, :date_created, :race, :subrace, :character_class, :primary, :secondary
	def to_s
		s = "Info:\n"
		indent = '   '
		s += "   Player Name: \"#{@player_name.gsub(/"/,'\"')}\"\n"
		s += "   Character Name: \"#{@name.gsub(/"/,'\"')}\"\n"
		s += "   Created: #{@date_created}\n"
		s += "   Race: #{@race}"
		s += "#{"\n   Subrace: \"#{@subrace.gsub(/"/,'\"')}\"" if subrace != ''}\n"
		s += "   Class: #{@character_class}\n"
		s += "   Primary School: \"#{@primary.gsub(/"/,'\"')}\"\n"
		s += "   Secondary School: \"#{@secondary.gsub(/"/,'\"')}\"\n"
		s += @death_history.to_s
		s += @spirit_effects.to_s
		s += @body_effects.to_s
		s += @build.to_s
		s += @experience.to_s
		s += "Backstory: >\n   "
		s += @backstory.split("\n").join("\n\n   ").split('. ').join(".\n   ")
		return s
	end

	def write filename
		File.open(filename,'w') do |f|
			f.write(self.to_s())
		end
	end

	def load filename
		yaml_parse = YAML.load(File.open(filename, 'r'))
		info = yaml_parse['Info']
		@player_name = info['Player Name']
		@name = info['Character Name']
		@date_created = info['Created']
		@race = NERO_Race.new info['Race']
		@character_class = NERO_Class.new info['Class']
		@primary = info['Primary School']
		@secondary = info['Secondary School']
		@death_history = Death_History.new info['Death History'], 1
		@spirit_effects = Formal_Effects.new 'Spirit', info['Spirit Effects'], 1
		@body_effects = Formal_Effects.new 'Body', info['Body Effects'], 1

		@build.load(yaml_parse['Build'])
		@experience.load(yaml_parse['Experience'])
		@backstory = yaml_parse['Backstory']
	end
end

class Spell_Tree
	attr_reader :school

	def initialize character, school
		@character = character
		@school = school

		@spells = [0]*9
	end

	# Sets the given spell to the specified amount
	# Example parameters: spell = "Celestial 1", amount = 3
	def set_spell( spell, amount )
		puts "Spell_Tree::set_spell(#{spell},#{amount})"
		@spells[spell.to_s.split(' ')[1].to_i - 1] = amount
	end

	# Returns the spell of the given descriptor
	# Example parameters: spell = "Celestial 1"
	def spell spell
		print spell
		if spell.to_s.split(' ')[0] != @school
			puts "Spell_Tree(#{@school})::spell(#{spell}) - passed spell is of inappropriate type"
		end
		@spells[spell.to_s.split(' ')[1].to_i - 1]
	end

	def spell_at level
		return 0 if !(level.is_a? Integer) or !@spells.include?(level-1)
		@spells[level - 1]
	end

	def spell_tree school
		@spells.clone
	end

	def set_tree tree
		puts "Build::set_tree(#{@school},#{tree.join '/'})"
		tree.each_with_index do |spell_count, i|
			@spells[i] = spell_count
		end
	end

	def spells_cost
		cost = 0
		(0..8).each do |i|
			cost += spell_cost(i) * @spells[i]
		end
		return cost
	end

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


	# This only ensures that it is legal to have a tree, NOT that the tree is built legally
	def legalize_spell_tree(build)
		case @school
		when 'Earth'
			@spells = [0] * 9 if @character.build.count('Healing Arts') <= 0
		when 'Celestial'
			@spells = [0] * 9 if @character.build.count('Read Magic') <= 0
		when 'Nature'
			@spells = [0] * 9 if @character.build.count('Runes of Nature') <= 0
		end
	end

	# Returns true if it's legal for this character to have spells
	# TODO: Make this return true if this tree is legal
	def legal_tree?
		case @school
		when 'Earth'
			return false if @spells[0] > 0 and @character.build.count('Healing Arts') <= 0
		when 'Celestial'
			return false if @spells[0] > 0 and @character.build.count('Read Magic') <= 0
		when 'Nature'
			return false if @spells[0] > 0 and @character.build.count('Runes of Nature') <= 0
		end
		return true
	end
end

class Death_History
	attr_reader :deaths
	def initialize death_list = nil, indent_level = 1
		death_list = [] if death_list.nil?
		@deaths = death_list
		@indent_l = indent_level
		@indent = '   '
	end

	def add_death type, event=nil, date=nil
		death = {'Type'=>type}
		death[event] = event if event != nil
		death[date]  = date if date != nil
		@deaths << death
	end

	def black_stones
		deaths = -1
		buybacks = 0
		forges = []
		@deaths.each do |death|
			case death['Type']
			when 'Death':
				deaths += 1
			when 'Obliterate':
				deaths += 3
			when 'Buyback':
				buybacks += 1
			when 'Spirit Forge':
				forges << death
			else
				puts "#{death['Type']} not a recognized death type"
			end
		end
		prev_forges = []
		forge_deaths = 0
		forges.each do |forge|
			prev_forges.each do |prev|
				if (forge['Date'] - prev).to_i < 365
					forge_deaths += 1
				end
			end
			prev_forges << forge['Date']
		end

		if deaths <= 1
			return deaths + forge_deaths
		end
		if deaths > 1
			after_buyback = deaths - buybacks
			if after_buyback >= 1
				return after_buyback + forge_deaths
			else
				return 1 + forge_deaths
			end
		end
	end

	def to_s
		s = @indent * @indent_l + "Death History:\n"
		@deaths.each do |death|
			s += "#{@indent * (@indent_l+1)}- Type:  \"#{death['Type'].gsub(/"/,'\"')}\"\n"
			s += "#{@indent * (@indent_l+1)}  Event: \"#{death['Event'].gsub(/"/,'\"')}\"\n" if death.has_key? 'Event'
			s += "#{@indent * (@indent_l+1)}  Date:  #{death['Date']}\n" if death.has_key? 'Date' and death['Date'].is_a? Date
			s += "#{@indent * (@indent_l+1)}  Date:  \"#{death['Date'].gsub(/"/,'\"')}\"\n" if death.has_key? 'Date' and death['Date'].is_a? String
		end
		return s
	end
end

class Formal_Effects
	def initialize location, effect_list = nil, indent_level = 1
		@location = location
		@effects = []
		if effect_list != nil
			effect_list.each do |effect|
				new_effect = {}
				new_effect['Effect'] =      effect['Effect']
				new_effect['Expires'] =     effect['Expires']
				new_effect['School'] =      effect['School']
				new_effect['Restriction'] = effect['Restriction']

				new_effect['Effect'] =      ''       if new_effect['Effect'].nil?
				new_effect['Expires'] =     Date.new if !new_effect['Expires'].is_a?(Date)
				new_effect['School'] =      ''       if new_effect['School'].nil?
				new_effect['Restriction'] = ''       if new_effect['Restriction'].nil?
				@effects << new_effect
			end
		end
		while @effects.length < 5
			effect = {}
			effect['Effect'] = ''
			effect['Expires'] = Date.today + 730
			effect['School'] = ''
			effect['Restriction'] = ''
			@effects << effect
		end

		while @effects.length > 5
			@effects.pop
		end

		@indent_l = indent_level
		@indent = '   '
	end

	def set_effect i, effect
		@effects[i]['Effect'] = effect
		puts "Formal_Effects::set_effect(#{i},#{effect}) : #{@effects[i]['Effect']}"
	end

	def set_expiration i, expiration
		@effects[i]['Expires'] = expiration
	end

	def set_school i, school
		@effects[i]['School'] = school
	end

	def set_restriction i, restriction
		@effects[i]['Restriction'] = restriction
	end

	def get_effect i
		@effects[i]['Effect']
	end

	def get_expiration i
		@effects[i]['Expires']
	end

	def get_school i
		@effects[i]['School']
	end

	def get_restriction i
		@effects[i]['Restriction']
	end

	def effects
		result = []
		@effects.each do |effect|
			if effect['Effect'] != '' and effect['Expires'] != ''
				result << effect
			end
		end
		return result
	end

	def to_s
		s = @indent * @indent_l + "#{@location} Effects:\n"
		self.effects().each do |effect|
			s += "#{@indent * (@indent_l+1)}- Effect:      \"#{effect['Effect'].gsub(/"/,'\"')}\"\n"
			s += "#{@indent * (@indent_l+1)}  Expires:     #{effect['Expires']}\n" if effect['Expires'].is_a? Date
			s += "#{@indent * (@indent_l+1)}  Expires:     \"#{effect['Expires'].gsub(/"/,'\"')}\"\n" if effect['Expires'].is_a? String
			s += "#{@indent * (@indent_l+1)}  School:      \"#{effect['School'].gsub(/"/,'\"')}\"\n"
			s += "#{@indent * (@indent_l+1)}  Restriction: \"#{effect['Restriction'].gsub(/"/,'\"')}\"\n"
		end
		return s
	end
end


class NERO_Class
	@@class_list = %w(Fighter Rogue Scholar Templar)
	@@class_initial_list = %w(F R S T)
	def initialize(character_class = @@class_list[0])
		@character_class = (@@class_list.include? character_class) ? character_class : @@class_list[0]
	end

	def name=(character_class)
		character_class.capitalize!
		if @@class_list.include?(character_class)
			return @character_class = character_class
		end
		if (character_class.is_a?(Integer) and character_class < @@class_list.length)
			return @character_class = @@class_list[character_class]
		end
		if @@class_initial_list.include?(character_class.to_s[0..0])
				return @character_class = @@class_list[@@class_initial_list.index(character_class.to_s[0..0])]
		end
		return false
	end

	def name
		return @character_class
	end

	def to_s
		return @character_class
	end
end

class NERO_Race
	@@race_list = %w(Barbarian Biata Drae Dwarf Elf Gypsy Half\ Ogre Half\ Orc Hobling Human Mystic\ Wood\ Elf Sarr Scavenger)

	attr_reader :race

	def initialize(race = @@race_list[0])
		race = race.split.map! { |s| s.capitalize }.join ' '
		@race = (@@race_list.include? race) ? race : @@race_list[0]
	end

	def to_s
		return race
	end

	def race= race
		if @@race_list.include? race
			return @race = race
		end
		if race.is_a? Integer and race < @@race_list.length
			return @race = @race_ary[race]
		end
		return false
	end
end


# Local Testing
if __FILE__ == $0
	$nero_skills = NERO_Skills.new


	puts "Testing character.rb"

	$c = NERO_Character.new

	$c2 = NERO_Character.new('test.yml')


	require 'irb'
	require 'irb/completion'
	IRB.start
end
