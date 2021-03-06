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
require 'yaml'

require 'experience.rb'
require 'build.rb'
require 'log.rb'

# The NERO_Character class contains all information associated with the character
# It also references the character's Build and Experience
class NERO_Character
	attr_reader :player_name, :name, :date_created, :race, :subrace, :character_class, :change_error
	attr_writer :player_name, :name, :date_created, :subrace, :backstory, :change_error
	attr_reader :experience, :primary, :secondary, :backstory, :build, :spirit_effects, :body_effects, :death_history
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

	# Assign the character's primary school of magic
	# Ensure the secondary is not the new primary; if it is, set the secondary to be the old primary
	def primary= school
		if @secondary == school
			@secondary = @primary
		end
		@primary = school
	end

	# Assign the character's secondary school of magic
	# Ensure the primary is not the new secondary; if it is, set the primary to be the old secondary
	def secondary= school
		if @primary == school
			@primary = @secondary
		end
		@secondary = school
	end

	# Calculate the character's body based on level, class, and race
	#
	# Class and race calculations are hard-coded.
	def calculate_body
		body = @character_class.body(@experience.level)
		body += @race.body

		return body
	end

	# Set the character's class.
	#
	# Prohibits changing to a prohibited class
	def character_class=( c_class )
		if @race.data.has_key?('Prohibited Classes') and @race.data['Prohibited Classes'].include?(c_class)
			@change_error = "A #{@race.to_s} cannot be a #{c_class}."
			$log.warn "NERO_Character.character_class=(#{c_class}) - Race prohibits this class."
			return false
		end
		@character_class = NERO_Class.new(c_class)
	end

	# Set the character's race.
	#
	# Hobling Fighter restriction is hard-coded and technically non-standard:
	# it sets the class to rogue if you attempt to change to a hobling as a fighter.
	# Technically it should instead revert the race, but I felt that would be unintuitive for the user.
	def race=( race )
		@race.race= race
		if @race.data.has_key?('Prohibited Classes') and @race.data['Prohibited Classes'].include?(@character_class.to_s)
			@change_error = "A #{race} cannot be a #{@character_class.to_s}. Setting the class to the racial default."
			$log.info "Resetting character class to the default class for the race, #{@race.data['Default Class']}"
			@character_class = NERO_Class.new(@race.data['Default Class'])
		end
		@build.legalize
	end

	# Return the total build spent.  This may be more than the character's total build.
	def build_spent()
		return @build.calculate_cost
	end

	# Return a YAML string that could be used to recreate this character
	def to_yaml
		YAML.dump self.export
	end
	
	def export
		return {'Info' => 
			{	'Player Name' => @player_name,
				'Character Name' => @name,
				'Created' => @date_created,
				'Race' => @race.to_s,
				'Subrace' => @subrace,
				'Class' => @character_class.to_s,
				'Primary School' => @primary,
				'Secondary School' => @secondary,
				'Death History' => @death_history.export,
				'Spirit Effects' => @spirit_effects.export,
				'Body Effects' => @body_effects.export
			},
			'Build' => @build.export,
			'Experience' => @experience.export,
			'Backstory' => @backstory
		}
	end

	# Return a YAML string that could be used to recreate this character.
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

	def to_html
		s = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<link href="./css/print_style.css" rel="stylesheet" type="text/css" />
<title>'

		s += "#{@player_name} - #{@name} - Temporary Character Sheet"


		s += '</title>
</head>
<body style="font-size:12px">
<table width="600" border="0">
	<tr>
		<td align="right"><strong>Character Name:</strong></td>
		<td><span id="c_name">'
		s += @name
		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td align="right"><strong>Total Build:</strong></td>
		<td><span id="t_build">'

		s += @experience.build.to_s

		s += '</span></td>
	</tr>
	<tr>
		<td align="right"><strong>Player Name:</strong></td>
		<td><span id="player_name">'

		s+= @player_name

		s+= '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td align="right"><strong>Spent Build:</strong></td>
		<td><span id="l_build">'

		s += @build.cost().to_s
		
		s += '</span></td>
	</tr>
	<tr>
		<td align="right"><strong>Home Chapter:</strong></td>
		<td><span id="home_c">'
		
		s += $config.setting('Chapter')

		
		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td align="right"><strong>Total XP:</strong></td>
		<td><span id="t_xp">'

		s += @experience.experience.to_s

		s += '</span></td>
	</tr>
	<tr>
		<td align="right"><strong>Race:</strong></td>
		<td><span id="race">'

		s += self.race.race
		unless self.subrace.empty?
			s += " (#{self.subrace})"
		end

		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td align="right"><strong>Loose XP:</strong></td>
		<td><span id="l_xp">'
		
		s += @experience.loose.to_s
		
		s += '</span></td>
	</tr>
	<tr>
		<td align="right"><strong>Class:</strong></td>
		<td><span id="c_class">'
		
		s += self.character_class.to_s
		
		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td align="right"><strong>XP per BP: </strong></td>
		<td><span id="XPBP">'

		s += Experience::xp_required_per_bp(@experience.level).to_s

		s += '</span></td>
	</tr>
	<tr>
		<td align="right"><strong>Level:</strong></td>
		<td><span id="level">'
		
		s += @experience.level.to_s
		
		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td align="right"><strong>Updated:</strong></td>
		<td><span id="tracker">'
		
		s += Time.now().strftime('%m/%d/%Y %I:%M:%S%P')
		
		s += '</span></td>
	</tr>
	<tr>
		<td align="right"><strong>Body Points: </strong></td>
		<td><span id="body_p">'

		s += self.calculate_body.to_i.to_s

		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td align="right"><strong>Static Deaths: </strong></td>
		<td><span id="s_death">'

		s += self.death_history.static_deaths.to_s

		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td align="right"><strong>Loose Deaths: </strong></td>
		<td><span id="l_death">'

		s += self.death_history.loose_deaths.to_s

		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td align="right"><strong>Last Spirit Forge: </strong></td>
		<td><span id="LSF">'

		unless self.death_history.spirit_forges.empty?
			date = self.death_history.spirit_forges[-1]['Date']
			s += "#{date.year}-#{date.month}-#{date.day}"
		end

		s += '</span></td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
	</tr>
</table>
<p>&nbsp;</p>
<table width="542" border="0">
	<tr>
		<td>&nbsp;</td>
		<td><div align="left"><strong>School</strong></div></td>
		<td><div align="center"><strong>1</strong></div></td>
		<td><div align="center"><strong>2</strong></div></td>
		<td><div align="center"><strong>3</strong></div></td>
		<td><div align="center"></div></td>
		<td><div align="center"><strong>4</strong></div></td>
		<td><div align="center"><strong>5</strong></div></td>
		<td><div align="center"><strong>6</strong></div></td>
		<td><div align="center"></div></td>
		<td><div align="center"><strong>7</strong></div></td>
		<td><div align="center"><strong>8</strong></div></td>
		<td><div align="center"><strong>9</strong></div></td>
		<td>&nbsp;</td>
		<td><div align="center"><strong>Spent</strong></div></td>
	</tr>
	<tr>
		<td width="70"><div align="right"><strong>Primary:</strong></div></td>

		<td width="80"><span id="primary">'

		s += @primary

		s += "</span></td>\n"

		[1,2,3,0,4,5,6,0,7,8,9].each do |spell_level|
			if spell_level == 0
				s += "\t\t<td width=\"25\"><div align=\"center\"></div></td>\n"
			else
				s += "\t\t<td width=\"25\"><div align=\"center\"><span id=\"p#{spell_level}\">#{@build.spell_at(@primary, spell_level)}</span></div></td>\n"
			end
		end

		s += '		<td width="25">&nbsp;</td>
	<td width="30"><div align="center"><span id="ptotal">'

		s += @build.spells_cost(@primary).to_s
	
		s += '</span></div></td>
	</tr>
	<tr>

		<td><div align="right"><strong>Secondary:</strong></div></td>
		<td><span id="secondary">'
		
		s += @secondary
		
		s += "</span></td>\n"
		[1,2,3,0,4,5,6,0,7,8,9].each do |spell_level|
			if spell_level == 0
				s += "\t\t<td width=\"25\"><div align=\"center\"></div></td>\n"
			else
				s += "\t\t<td width=\"25\"><div align=\"center\"><span id=\"p#{spell_level}\">#{@build.spell_at(@secondary, spell_level)}</span></div></td>\n"
			end
		end
		s += '<td>&nbsp;</td>
	<td><div align="center"><span id="stotal">'

		s += @build.spells_cost(@secondary).to_s

		s += "\t\t</span></div></td>\n</tr>\n</table>\n"

		s += '<p>&nbsp;</p>
<table width="650" border="0">
	<tr>
		<td><div align="right"><strong>Skill Name</strong></div></td>
		<td><div align="center"><strong>Num</strong></div></td>
		<td><div align="center"><strong>Cost</strong></div></td>
		<td><div align="left"><strong>Options</strong></div></td>
	</tr>
'

		@build.skills.each_with_index do |skill, i|
			s += "\t<tr>\n\t\t<td align=\"right\"><span id=\"skill#{i}\">#{skill.to_s}</span></td>\n"
			s += "\t\t<td align=\"center\"><span id=\skill#{i}_num\">#{skill.count}</span></td>\n"
    		s += "\t\t<td align=\"center\"><span id=\"skill#{i}_cost\">#{skill.cost}</span></td>\n"
    		s += "\t\t<td align=\"left\"><span id=\"skill#{i}_option\">"
			
			skill.options.each do |option, value|
				s += "(#{option}: #{value}) "
			end

			s += "</span></td>\n\t</tr>"
		end

		s += '</table>
<table width="600">
<tr>
<td><strong>Notes</strong></td>
</tr>
<tr>
<td><span id="notes"><div id="text">'

		s += "THIS IS A TEMPORARY CHARACTER SHEET GENERATED ON SITE.<br />\n"
		s += @spirit_effects.to_html
		s += @body_effects.to_html
		s += @backstory.gsub("\n","<br />\n")

		s += '</div></span></td>
</tr>
</table>
</body>
</html>'
		
		$log.debug "HTML: #{s}"
		return s
	end

	def write filename
		File.open(filename,'w') do |f|
			f.write(self.to_s())
		end
	end

	def load filename
		begin
			yaml_parse = {}
			File.open(filename, 'r') do |file|
				yaml_parse = YAML.load(file)
			end
			info = yaml_parse['Info']
			@player_name = info['Player Name']
			@name = info['Character Name']
			@date_created = info['Created']
			@race = NERO_Race.new info['Race']
			@subrace = info['Subrace']
			@character_class = NERO_Class.new info['Class']
			@primary = info['Primary School']
			@secondary = info['Secondary School']
			@death_history = Death_History.new info['Death History'], 1
			@spirit_effects = Formal_Effects.new 'Spirit', info['Spirit Effects'], 1
			@body_effects = Formal_Effects.new 'Body', info['Body Effects'], 1
	
			@build.load(yaml_parse['Build'])
			@experience.load(yaml_parse['Experience'])
			@backstory = yaml_parse['Backstory']
		rescue Exception => e
			$log.error "Failed to load character!"
			$log.error e.inspect
			$log.error e.backtrace
			return false
		end
	end
end

class Death_History
	attr_reader :deaths
	def initialize death_list = nil, indent_level = 1
		$log.info "Loading Death List: [#{death_list.join(',')}]" unless death_list.nil?
		death_list = [] if death_list.nil?
		@deaths = death_list
		@indent_l = indent_level
		@indent = '   '
	end

	def add_death type, date
		death = {'Type'=>type, 'Date' => date}
		@deaths << death
	end

	def white_stones
		10 - self.black_stones
	end

	def black_stones
		deaths = -1
		buybacks = 0
		forges = []
		@deaths.each do |death|
			case death['Type']
			when 'Death' then
				deaths += 1
			when 'Obliterate' then
				deaths += 3
			when 'Buyback' then
				buybacks += 1
			when 'Spirit Forge' then
				forges << death
			else
				$log.warn "#{death['Type']} is not a recognized death type"
			end
		end
		prev_forges = []
		forge_deaths = 0
		forges.each do |forge|
			prev_forges.each do |prev|
				if (forge['Date'] - prev['Date']).to_i.abs < 365
					forge_deaths += 1
				end
			end
			prev_forges << forge
		end

		if deaths <= 1
			return [0,[deaths + forge_deaths,9].min].max
		end
		if deaths > 1
			return [9, [deaths - buybacks, 1].max + forge_deaths].min
		end
	end

	def delete_last_entry
		@deaths.pop
	end

	def static_deaths
		deaths = 0
		forges = []
		@deaths.each do |death|
			case death['Type']
			when 'Death' then
				deaths += 1
			when 'Obliterate' then
				deaths += 3
			when 'Spirit Forge' then
				forges << death
			end
		end
		prev_forges = []
		forge_deaths = 0
		forges.each do |forge|
			prev_forges.each do |prev|
				if (forge['Date'] - prev['Date']).to_i.abs < 365
					forge_deaths += 1
				end
			end
			prev_forges << forge
		end

		return [2,deaths].min + forge_deaths
	end

	def loose_deaths
		deaths = 0
		@deaths.each do |death|
			case death['Type']
			when 'Death' then
				deaths += 1
			when 'Obliterate' then
				deaths += 3
			when 'Buyback' then
				deaths -= 1
			end
		end
		return [0,deaths-2].max
	end

	def spirit_forges
		forges = []
		@deaths.each do |death|
			next if death['Type'] != 'Spirit Forge'
			inserted = false
			forges.each_with_index do |forge,i|
				if death['Date'] < forge['Date']
					inserted = true
					forges.insert(i, death)
					date_text = "#{death['Date'].year}-#{death['Date'].month}-#{death['Date'].day}"
					$log.debug "Inserting forge at date #{date_text} at position #{i}"
					break
				end
			end
			#forges.each_with_index do |forge,i|
			#	$log.debug "forges[#{i}] = #{forge['Date']}"
			#end
			forges << death unless inserted
		end
		return forges
	end

	def to_text
		text = ""
		@deaths.each do |death|
			date_text = "#{death['Date'].year}-#{death['Date'].month}-#{death['Date'].day}"
			text += "#{death['Type']} (#{date_text})\r\n"
		end
		return text
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

	def export
		@deaths.clone
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
		$log.info "Formal_Effects::set_effect(#{i},#{effect}) : #{@effects[i]['Effect']}"
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

	def export
		self.effects()
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

	def to_html
		html = ""
		self.effects().each do |effect|
			html << "#{@location}: (#{effect['School']}, #{effect['Restriction']}, Expires #{effect['Expires']}) #{effect['Effect']}<br />\n"
		end

		return html
	end
end





# Local Testing
if __FILE__ == $0
	$log = Logger.new('character.log',10,102400)
	$log.info "Testing character.rb"


	NERO_Data.initialize_statics 'ncc.yml'

	c = NERO_Character.new

	c2 = NERO_Character.new('test.yml')


	require 'irb'
	require 'irb/completion'
	IRB.start
end
