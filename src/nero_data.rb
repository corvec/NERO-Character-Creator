#!/usr/bin/env ruby

require 'nero_skills.rb'
require 'nero_race.rb'
require 'nero_class.rb'


# Contains generic information about NERO Constructs:
# * Skills
# * Races
# * Classes
# * Schools of Magic
class NERO_Data
	@@initialized = false
	attr_reader :skills, :races, :classes, :schools
	def NERO_Data::initialize_statics(filename)
		$log.info "NERO_Data::initialize(#{filename})"

		begin
			self.add_file(filename)
		rescue
			begin
				self.add_file(File.join($config.setting('Working Directory'),filename))
			rescue
				$log.fatal("Could not load Primary Module: #{filename}")
				return false
			end
		end
		num = 1
		until $config.setting("Module #{num}").nil?
			begin
				self.add_file($config.setting)
			rescue
				begin
					$log.info("Could not load Module #{$config.setting} in current directory.  Trying working directory.")
					self.add_file(File.join($config.setting('Working Directory'),$config.setting("Module #{num}")))
				rescue
					$log.error("Could not load Module #{$config.setting}")
				end
			end
			num += 1
		end
		@@initialized = true
	end

	def NERO_Data::initialized?
		@@initialized
	end

	# Adds entries from a file:
	# * skills
	# * schools of magic
	# * spells
	# * races
	# * classes
	def NERO_Data::add_file filename
		$log.info "Adding file #{filename} to game data"
		data = {}
		File.open(filename) do |file|
			data = YAML.load(file)
		end
		$log.debug "#{filename}: contains data for: #{data.keys.inspect}"

		# Add skills
		if data.has_key? 'Skills'
			NERO_Skill.add_skills(data['Skills'])
			$log.debug "#{filename}: Skills added successfully"
		end

		# Add schools of magic and spells
		if data.has_key? 'Schools of Magic' and data.has_key? 'Spell Costs'
			NERO_Skill.add_magic(data['Schools of Magic'],data['Spell Costs'])
			$log.debug "#{filename}: Spells added successfully"
		end

		# Add races if it contains an entry for 'Races'
		if data.has_key? 'Races'
			NERO_Race.add_races(data['Races']) 
			$log.debug "#{filename}: Races added successfully"
		end

		# Add classes if it contains an entry for 'Classes'
		if data.has_key? 'Classes'
			NERO_Class.add_classes(data['Classes'])
			$log.debug "#{filename}: Classes added successfully"
		end
	end
end
