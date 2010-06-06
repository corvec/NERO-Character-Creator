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

$LOAD_PATH << './src'

require 'log.rb'
require 'character.rb'
require 'build.rb'
require 'character_skill.rb'
require 'nero_skills.rb'

require 'rubygems'
require 'Qt4'

require 'date'

# If added to the list of tabs, this will automatically save to the passed file every time the tabs are all updated.
class AutoSaver
	def initialize(filename)
		@filename = filename
	end

	def update
		File.open(@filename,'w') { |f|
			f.write($character.to_yaml)
		}
	end
end

class InfoWidget < Qt::Widget
	def initialize(parent=nil)
		super(parent)

		base_layout = Qt::VBoxLayout.new(self)

		info_and_deaths_layout = Qt::HBoxLayout.new(nil)
		formal_layout = Qt::HBoxLayout.new(nil)

		info_frame = Qt::Frame.new(self)
		info_frame.frameShadow= Qt::Frame::Raised
		info_frame.frameShape= Qt::Frame::StyledPanel
		info_layout = Qt::GridLayout.new(info_frame)

		deaths_frame = Qt::Frame.new(self)
		deaths_frame.frameShadow= Qt::Frame::Raised
		deaths_frame.frameShape= Qt::Frame::StyledPanel
		deaths_layout = Qt::GridLayout.new(deaths_frame)

		# Info data
		@playername_entry = Qt::LineEdit.new(nil)
		@playername_entry.connect(SIGNAL(:editingFinished)) {
			$character.player_name = @playername_entry.text
		}
		@name_entry = Qt::LineEdit.new(nil)
		@name_entry.connect(SIGNAL(:editingFinished)) {
			$character.name = @name_entry.text
		}
		@creation_entry = Qt::DateEdit.new(Qt::Date::currentDate(), self)
		@creation_entry.calendarPopup= true
		@creation_entry.displayFormat='yyyy/MM/dd'
		@creation_entry.connect(SIGNAL(:editingFinished)) {
			temp_date = @creation_entry.date
			$character.date_created= Date.new(temp_date.year,temp_date.month,temp_date.day)
		}
		@race_entry = Qt::LineEdit.new(nil)
		race_list = %w(Barbarian Biata Drae Dwarf Elf Gypsy Half\ Ogre Half\ Orc Hobling Human Mystic\ Wood\ Elf Sarr Scavenger)
		race_completer = Qt::Completer.new(race_list,nil)
		race_completer.completionMode= Qt::Completer::InlineCompletion
		@race_entry.setCompleter(race_completer)
		@race_entry.connect(SIGNAL(:editingFinished)) {
			$character.race = @race_entry.text
			@race_entry.text= $character.race.to_s
			self.commit()
		}

		@subrace_entry = Qt::LineEdit.new(nil)
		@subrace_entry.connect(SIGNAL(:editingFinished)) {
			$character.subrace = @subrace_entry.text
		}

		@class_entry = Qt::LineEdit.new(nil)
		class_list = %w(Fighter Rogue Scholar Templar)
		class_completer = Qt::Completer.new(class_list,nil)
		class_completer.completionMode = Qt::Completer::InlineCompletion#UnfilteredPopupCompletion
		@class_entry.setCompleter(class_completer)
		@class_entry.connect(SIGNAL(:editingFinished)) {
			$character.character_class = @class_entry.text
			@class_entry.text = $character.character_class.name
			self.commit()
		}

		@primary_school_entry = Qt::LineEdit.new(nil)
		school_list = %w(Earth Celestial Nature)
		school_completer = Qt::Completer.new(school_list,nil)
		school_completer.completionMode = Qt::Completer::InlineCompletion#UnfilteredPopupCompletion
		@primary_school_entry.setCompleter(school_completer)
		@primary_school_entry.connect(SIGNAL(:editingFinished)) {
			school_init = @primary_school_entry.text[0..0]
			if %w(E C N).include? school_init
				$character.primary = %w(Earth Celestial Nature)[ %w(E C N).index(school_init) ]
			end
			@primary_school_entry.text = $character.primary
			@secondary_school_entry.text = $character.secondary
			self.commit()
		}
		@secondary_school_entry = Qt::LineEdit.new(nil)
		@secondary_school_entry.setCompleter(school_completer)
		@secondary_school_entry.connect(SIGNAL(:editingFinished)) {
			school_init = @secondary_school_entry.text[0..0]
			if %w(E C N).include? school_init
				$character.secondary = %w(Earth Celestial Nature)[ %w(E C N).index(school_init) ]
			end
			@primary_school_entry.text = $character.primary
			@secondary_school_entry.text = $character.secondary
			self.commit()
		}
		@level_label = Qt::Label.new('2',nil)
		@body_label = Qt::Label.new('5',nil)

		i = 0
		info_layout.addWidget(Qt::Label.new('Player Name:'),i,0)
		info_layout.addWidget(@playername_entry,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Character Name:'),i,0)
		info_layout.addWidget(@name_entry,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Date Created:'),i,0)
		info_layout.addWidget(@creation_entry,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Race:'),i,0)
		info_layout.addWidget(@race_entry,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Subrace:'),i,0)
		info_layout.addWidget(@subrace_entry,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Class:'),i,0)
		info_layout.addWidget(@class_entry,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Primary School:'),i,0)
		info_layout.addWidget(@primary_school_entry,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Secondary School:'),i,0)
		info_layout.addWidget(@secondary_school_entry,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Level:'),i,0)
		info_layout.addWidget(@level_label,i,1)
		i += 1
		info_layout.addWidget(Qt::Label.new('Body:'),i,0)
		info_layout.addWidget(@body_label,i,1)


		# Death data
		deaths_layout.addWidget(Qt::Label.new('Death History',nil),0,0,1,2)
		@death_history_box = Qt::TextEdit.new(nil)
		@death_history_box.readOnly= true
		deaths_layout.addWidget(@death_history_box,1,0,1,2)

		death_banner = Qt::HBoxLayout.new(nil)
		death_banner.addWidget(Qt::Label.new('White Stones:'))
		@white_stones = Qt::Label.new('10')
		death_banner.addWidget(@white_stones)
		death_banner.addWidget(Qt::Label.new('Black Stones:'))
		@black_stones = Qt::Label.new('0')
		death_banner.addWidget(@black_stones)

		deaths_layout.addLayout(death_banner,2,0,1,2)

		@button_add_death = Qt::PushButton.new('Add Death')
		@button_buy_back_death = Qt::PushButton.new('Buy Back Death')
		@button_spirit_forge = Qt::PushButton.new('Spirit Forge')
		@button_del_death = Qt::PushButton.new('Delete Last Entry')
		@death_date = Qt::DateEdit.new(Qt::Date::currentDate(),self)
		@death_date.displayFormat='yyyy/MM/dd'
		@death_date.calendarPopup=true

		@button_add_death.connect(SIGNAL(:clicked)) {
			temp_date = Date.new(@death_date.date.year,@death_date.date.month,@death_date.date.day)
			$character.death_history.add_death('Death',temp_date)
			@black_stones.text = $character.death_history.black_stones.to_s
			@white_stones.text = $character.death_history.white_stones.to_s
			@death_history_box.text = $character.death_history.to_text
		}

		@button_buy_back_death.connect(SIGNAL(:clicked)) {
			temp_date = Date.new(@death_date.date.year,@death_date.date.month,@death_date.date.day)
			$character.death_history.add_death('Buyback',temp_date)
			@black_stones.text = $character.death_history.black_stones.to_s
			@white_stones.text = $character.death_history.white_stones.to_s
			@death_history_box.text = $character.death_history.to_text
		}

		@button_spirit_forge.connect(SIGNAL(:clicked)) {
			temp_date = Date.new(@death_date.date.year,@death_date.date.month,@death_date.date.day)
			$character.death_history.add_death('Spirit Forge',temp_date)
			@black_stones.text = $character.death_history.black_stones.to_s
			@white_stones.text = $character.death_history.white_stones.to_s
			@death_history_box.text = $character.death_history.to_text
		}

		@button_del_death.connect(SIGNAL(:clicked)) {
			$character.death_history.delete_last_entry()
			@black_stones.text = $character.death_history.black_stones.to_s
			@white_stones.text = $character.death_history.white_stones.to_s
			@death_history_box.text = $character.death_history.to_text
		}


		deaths_layout.addWidget(@button_add_death)
		deaths_layout.addWidget(@button_buy_back_death)
		deaths_layout.addWidget(@button_spirit_forge)
		deaths_layout.addWidget(@death_date)
		deaths_layout.addWidget(@button_del_death)

		info_and_deaths_layout.addWidget(info_frame)
		info_and_deaths_layout.addWidget(deaths_frame)

		# Formal Magic Effects on Spirit and Body:
		spirit_frame = Qt::Frame.new(self)
		body_frame = Qt::Frame.new(self)

		spirit_frame.frameShadow= Qt::Frame::Raised
		spirit_frame.frameShape= Qt::Frame::StyledPanel
		body_frame.frameShadow= Qt::Frame::Raised
		body_frame.frameShape= Qt::Frame::StyledPanel

		@spirit_layout = FormalMagicEffects.new(spirit_frame,'Spirit',school_completer)
		@body_layout   = FormalMagicEffects.new(body_frame,'Body',school_completer)

		formal_layout.addWidget(spirit_frame)
		formal_layout.addWidget(body_frame)

		base_layout.addLayout(info_and_deaths_layout)
		base_layout.addLayout(formal_layout)
	end

	def startup
		# Set the focus to the first field
		# (setting it to the date created field is annoying)
		@playername_entry.setFocus()
	end

	def commit
		$tabs.each do |tab|
			tab.update
		end
	end

	def update
		@playername_entry.text = $character.player_name
		@name_entry.text= $character.name
		if create.is_a? String
			create = $character.date_created.split('-')
			@creation_entry.date= Qt::Date.new(create[0].to_i,create[1].to_i,create[2].to_i)
		elsif create.is_a? Date
			@creation_entry.date= Qt::Date.new(create.year,create.month,create.day)
		else
			@creation_entry.date= Qt::Date.new()
		end

		@race_entry.text= $character.race.to_s
		@subrace_entry.text= $character.subrace
		@class_entry.text= $character.character_class.to_s
		@primary_school_entry.text= $character.primary
		@secondary_school_entry.text= $character.secondary
		@level_label.text= $character.experience.level
		@body_label.text= $character.calculate_body.to_i

		@spirit_layout.update()
		@body_layout.update()

		@black_stones.text = $character.death_history.black_stones.to_s
		@white_stones.text = $character.death_history.white_stones.to_s
		@death_history_box.text = $character.death_history.to_text
	end
end


class SkillsWidget < Qt::ScrollArea
	def initialize(build_widget,parent=nil)
		super(parent)
		@build_widget = build_widget
		self.update()
	end

	def update()
		old_frame = self.takeWidget()
		old_frame.deleteLater if old_frame != nil
		@grid = Qt::GridLayout.new(nil) #the old grid should automatically be destroyed
		@skills = $character.build.skills
		@skills.each_with_index do |skill,i|
			@grid.addWidget(Qt::Label.new(skill.name,nil),i,1)
			skill_cost_label = Qt::Label.new(skill.cost().to_s,nil)
			@grid.addWidget(skill_cost_label,i,3)
			if skill.skill.limit != 1
				skill_count_frame = Qt::Frame.new(self)
				skill_count_layout = Qt::GridLayout.new(skill_count_frame)

				skill_count_label = Qt::Label.new("#{skill.count.to_s}X",nil)
				skill_count_layout.addWidget(skill_count_label,0,0,1,2)

				skill_count_dec = Qt::PushButton.new('-',nil)
				skill_count_dec.setMinimumWidth(10)
				skill_count_dec.setMinimumHeight(10)
				skill_count_dec.setMaximumWidth(20)
				skill_count_dec.setMaximumHeight(20)

				skill_count_dec.connect(SIGNAL(:clicked)) {
					domino = $character.build.legally_delete_skill skill.name, skill.options

					$log.debug "Domino: #{domino}"

					if domino or ($character.build.count(skill.name, skill.options) <= 0)
						self.commit
					else
						skill_count_label.text = "#{skill.count.to_s}X"
						skill_cost_label.text = skill.cost().to_s
						@build_widget.update_banner()
					end
				}

				skill_count_inc = Qt::PushButton.new('+',nil)
				skill_count_inc.setMinimumWidth(10)
				skill_count_inc.setMinimumHeight(10)
				skill_count_inc.setMaximumWidth(20)
				skill_count_inc.setMaximumHeight(20)

				skill_count_inc.connect(SIGNAL(:clicked)) {
					$character.build.add_skill(skill.skill,skill.options)
					skill_count_label.text = "#{skill.count.to_s}X"
					skill_cost_label.text = skill.cost().to_s
					@build_widget.update_banner
				}

				skill_count_layout.addWidget(skill_count_dec,1,0)
				skill_count_layout.addWidget(skill_count_inc,1,1)

				@grid.addWidget(skill_count_frame,i,0)
			else
				remove_skill_button = Qt::PushButton.new('X',nil)
				remove_skill_button.connect(SIGNAL(:clicked)) {
					$character.build.legally_delete_skill skill.name, skill.options
					self.commit()
				}
				@grid.addWidget(remove_skill_button,i,0)
			end

			if skill.options != nil and skill.options.length > 0
				options_frame = Qt::Frame.new(self)
				options_grid = Qt::GridLayout.new(options_frame)

				j = 0
				skill.options.each do |o,v|
					options_grid.addWidget(Qt::Label.new("#{o}:"),j,0)
					options_grid.addWidget(Qt::Label.new("#{v}"),j,1)
					j += 1
				end

				@grid.addWidget(options_frame,i,2)
			end
		end
		@frame = Qt::Frame.new()
		@frame.setLayout(@grid)
		self.setWidget(@frame)
	end
	def commit
		$tabs.each do |tab|
			tab.update
		end
	end
end

class BuildWidget < Qt::Widget
	def initialize(parent=nil)
		super(parent)

		base_layout = Qt::VBoxLayout.new(self)

		# Frames
		banner_frame = Qt::Frame.new(self)
		add_skill_frame = Qt::Frame.new(self)
		known_skills_frame = Qt::Frame.new(self)

		# Give the frames borders:
		banner_frame.frameShadow = Qt::Frame::Raised
		banner_frame.frameShape = Qt::Frame::StyledPanel
		add_skill_frame.frameShadow = Qt::Frame::Raised
		add_skill_frame.frameShape = Qt::Frame::StyledPanel
		known_skills_frame.frameShadow = Qt::Frame::Raised
		known_skills_frame.frameShape = Qt::Frame::StyledPanel

		banner_layout = Qt::HBoxLayout.new(banner_frame)
		add_skill_layout = Qt::GridLayout.new(add_skill_frame)
		known_skills_layout = Qt::VBoxLayout.new(known_skills_frame)

		# Banner
		banner_layout.addWidget(Qt::Label.new('Total:',nil))
		@build_total = Qt::Label.new($character.experience.build.to_s,nil)
		banner_layout.addWidget(@build_total)
		banner_layout.addWidget(Qt::Label.new('Spent:',nil))
		@spent_build = Qt::Label.new('0',nil)
		banner_layout.addWidget(@spent_build)
		banner_layout.addWidget(Qt::Label.new('Loose:',nil))
		@loose_build = Qt::Label.new($character.experience.build.to_s,nil)
		banner_layout.addWidget(@loose_build)

		# Skill Addition
		skill_frame = Qt::Frame.new(self)
		skill_frame.frameStyle = Qt::Frame::Raised
		skill_frame.frameShape = Qt::Frame::StyledPanel

		skill_layout = Qt::GridLayout.new(skill_frame)
		skill_layout.addWidget(Qt::Label.new('Learn a new Skill:',nil),0,0,1,3)

		#@skill_entry = Qt::LineEdit.new(nil)
		@skill_entry = Qt::ComboBox.new(nil)
		skill_list = self.build_skill_list()
		$log.info "Skill list length: #{skill_list.length}"
		
		#skill_completer = Qt::Completer.new(skill_list,nil)
		#skill_completer.completionMode= Qt::Completer::UnfilteredPopupCompletion
		#@skill_entry.setCompleter(skill_completer)
		@skill_entry.add_items skill_list
		
		skill_layout.addWidget(@skill_entry, 1,0,1,2)
		skill_layout.addWidget(Qt::Label.new('Note',nil),2,0)
		@skill_options_entry = Qt::LineEdit.new(nil)
		skill_layout.addWidget(@skill_options_entry,2,1)
		skill_entry_button = Qt::PushButton.new('Add',nil)
		#@skill_entry.connect(SIGNAL(:returnPressed)) {
			#self.add_entered_skill()
		#}
		@skill_options_entry.connect(SIGNAL(:returnPressed)) {
			self.add_entered_skill_combo()
		}
		skill_entry_button.connect(SIGNAL(:clicked)) {
			self.add_entered_skill_combo()
		}
		skill_layout.addWidget(skill_entry_button, 1,2,2,1)

		add_skill_layout.addWidget(skill_frame,0,0)

		# Spell Trees
		primary_tree_frame = Qt::Frame.new(self)
		secondary_tree_frame = Qt::Frame.new(self)

		primary_tree_frame.frameStyle = Qt::Frame::Raised
		primary_tree_frame.frameShape = Qt::Frame::StyledPanel

		secondary_tree_frame.frameStyle = Qt::Frame::Raised
		secondary_tree_frame.frameShape = Qt::Frame::StyledPanel

		@primary_tree_layout = SpellTreeLayout.new(primary_tree_frame, 'Primary',base_cost = 1)
		@secondary_tree_layout = SpellTreeLayout.new(secondary_tree_frame, 'Secondary',base_cost = 2)

		add_skill_layout.addWidget(primary_tree_frame,0,1)
		add_skill_layout.addWidget(secondary_tree_frame,1,1)


		# Known Skills
		known_skills_layout.addWidget(Qt::Label.new('Known Skills:',nil))
		#@skill_list = Qt::TextEdit.new(nil)
		@skill_list = SkillsWidget.new(self,nil)
		known_skills_layout.addWidget(@skill_list)


		base_layout.addWidget(banner_frame)
		base_layout.addWidget(add_skill_frame)
		base_layout.addWidget(known_skills_frame)
	end

	def add_entered_skill
		if !$character.build.add_skill @skill_entry.text, @skill_options_entry.text
			err = Qt::MessageBox.new(nil,'Error Adding Skill',$character.build.get_add_error())
			err.show()
		else
			@skill_entry.text = ''
			@skill_options_entry.text = ''
			@skill_entry.setFocus()
		end
		self.commit()
	end

	def add_entered_skill_combo
		if !$character.build.add_skill @skill_entry.current_text, @skill_options_entry.text
			err = Qt::MessageBox.new(nil,'Error Adding Skill',$character.build.get_add_error())
			err.show()
		else
			@skill_entry.current_index = 0
			@skill_options_entry.text = ''
			@skill_entry.setFocus()
		end
		self.commit()
	end

	def build_skill_list()
		skill_list = ['']
		begin
			File.open( $data_path + 'skills' ) { |file|
				while line = file.gets
					skill_list << line.strip
				end
			}
		rescue
			$log.error "Skill autocompletion file not found!  Cannot build skill list!"
		end
		return skill_list
	end

	def commit
		$tabs.each do |tab|
			tab.update
		end
	end

	def update_banner
		@build_total.text = $character.experience.build.to_s
		@spent_build.text = $character.build_spent.to_s
		@loose_build.text = ($character.experience.build - $character.build_spent).to_s
	end

	def update
		self.update_banner

		@primary_tree_layout.update
		@secondary_tree_layout.update

		@skill_list.update
	end
end

class ExperienceWidget < Qt::Widget
	def initialize(parent=nil)
		super(parent)

		base_layout = Qt::VBoxLayout.new(self)

		#Main Body:
		banner_frame = Qt::Frame.new(self)
		banner_frame.frameStyle = Qt::Frame::Raised
		banner_frame.frameShape = Qt::Frame::StyledPanel
		banner_layout = Qt::HBoxLayout.new(banner_frame)
		add_experience_layout = Qt::GridLayout.new(nil)
		@experience_history = Qt::TextEdit.new(nil)
		@experience_history.readOnly= true

		# Banner
		banner_layout.addWidget(Qt::Label.new('Experience:',nil))
		@experience_total = Qt::Label.new('0',nil)
		banner_layout.addWidget(@experience_total)
		banner_layout.addWidget(Qt::Label.new('Build:',nil))
		@build_total = Qt::Label.new('0',nil)
		banner_layout.addWidget(@build_total)
		banner_layout.addWidget(Qt::Label.new('Loose Experience:',nil))
		@loose_experience = Qt::Label.new('0',nil)
		banner_layout.addWidget(@loose_experience)


		# Frames (for borders)
		add_event_frame = Qt::Frame.new(self)
		add_goblins_frame = Qt::Frame.new(self)
		add_custom_frame = Qt::Frame.new(self)

		# Actually add the borders:
		add_event_frame.frameShadow= Qt::Frame::Raised
		add_event_frame.frameShape= Qt::Frame::StyledPanel

		add_goblins_frame.frameShadow= Qt::Frame::Raised
		add_goblins_frame.frameShape= Qt::Frame::StyledPanel

		add_custom_frame.frameShadow= Qt::Frame::Raised
		add_custom_frame.frameShape= Qt::Frame::StyledPanel

		# Layout the Frames
		add_event_layout = Qt::GridLayout.new(add_event_frame)
		add_goblins_layout = Qt::HBoxLayout.new(add_goblins_frame)
		add_custom_layout = Qt::HBoxLayout.new(add_custom_frame)

		# Layout for Adding an Event
		add_event_layout.addWidget(Qt::Label.new('Add Event:',nil),0,0,1,3)
		add_event_layout.addWidget(Qt::Label.new('Location:',nil),1,0)
		@add_event_name = Qt::LineEdit.new('',nil)
		add_event_layout.addWidget(@add_event_name,1,1)
		@add_event_date = Qt::DateEdit.new(Qt::Date::currentDate(), self)
		@add_event_date.calendarPopup= true
		@add_event_date.displayFormat='yyyy/MM/dd'
		add_event_layout.addWidget(@add_event_date,1,2)
		add_event_layout.addWidget(Qt::Label.new('1-Day',nil),2,0)
		@add_event_1_day_no_maxout = Qt::PushButton.new('No Maxout',nil)
		@add_event_1_day_no_maxout.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_pc_event(
				@add_event_name.text, Date.new(td.year,td.month,td.day), 1, false)
			self.commit()
		}
		add_event_layout.addWidget(@add_event_1_day_no_maxout,2,1)
		@add_event_1_day_maxout = Qt::PushButton.new('Maxout',nil)
		@add_event_1_day_maxout.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_pc_event(
				@add_event_name.text, Date.new(td.year,td.month,td.day), 1, true)
			self.commit()
		}
		add_event_layout.addWidget(@add_event_1_day_maxout,2,2)
		add_event_layout.addWidget(Qt::Label.new('2-Day',nil),3,0)
		@add_event_2_day_no_maxout = Qt::PushButton.new('No Maxout',nil)
		@add_event_2_day_no_maxout.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_pc_event(
				@add_event_name.text, Date.new(td.year,td.month,td.day), 2, false)
			self.commit()
		}
		add_event_layout.addWidget(@add_event_2_day_no_maxout,3,1)
		@add_event_2_day_maxout = Qt::PushButton.new('Maxout',nil)
		@add_event_2_day_maxout.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_pc_event(
				@add_event_name.text, Date.new(td.year,td.month,td.day), 2, true)
			self.commit()
		}
		add_event_layout.addWidget(@add_event_2_day_maxout,3,2)

		# Layout for Adding goblins
		add_goblins_layout.addWidget(Qt::Label.new('Goblin Blanket'))
		goblin_button_1 = Qt::PushButton.new('1 Week')
		goblin_button_1.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_goblin_blankets Date.new(td.year,td.month,td.day), 1
			self.commit
		}
		add_goblins_layout.addWidget(goblin_button_1)
		goblin_button_2 = Qt::PushButton.new('4 Weeks')
		goblin_button_2.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_goblin_blankets Date.new(td.year,td.month,td.day), 4
			self.commit
		}
		add_goblins_layout.addWidget(goblin_button_2)
		goblin_button_3 = Qt::PushButton.new('5 Weeks')
		goblin_button_3.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_goblin_blankets Date.new(td.year,td.month,td.day), 5
			self.commit
		}
		add_goblins_layout.addWidget(goblin_button_3)

		# Layout for Custom Blankets
		add_custom_layout.addWidget(Qt::Label.new('Custom: Add'))
		@custom_number = Qt::LineEdit.new('1',nil)
		@custom_number.setMaxLength(1)
		@custom_number.setMaximumWidth(20)
		add_custom_layout.addWidget(@custom_number)
		add_custom_layout.addWidget(Qt::Label.new('Blanket'))
		@custom_times = Qt::LineEdit.new('1')
		@custom_times.setMaxLength(2)
		@custom_times.setMaximumWidth(40)
		add_custom_layout.addWidget(@custom_times)
		add_custom_layout.addWidget(Qt::Label.new('times.'))
		@custom_add_button = Qt::PushButton.new('Submit')
		@custom_number.connect(SIGNAL(:returnPressed)) {
			$character.experience.add_custom @custom_number.text.to_i, @custom_times.text.to_i
			self.commit
		}
		@custom_times.connect(SIGNAL(:returnPressed)) {
			$character.experience.add_custom @custom_number.text.to_i, @custom_times.text.to_i
			self.commit
		}
		@custom_add_button.connect(SIGNAL(:clicked)) {
			$character.experience.add_custom @custom_number.text.to_i, @custom_times.text.to_i
			self.commit
		}
		add_custom_layout.addWidget(@custom_add_button)

		add_experience_layout.addWidget(add_event_frame,0,0,2,1)
		add_experience_layout.addWidget(add_goblins_frame,0,1)
		add_experience_layout.addWidget(add_custom_frame,1,1)


		base_layout.addWidget(banner_frame)
		base_layout.addLayout(add_experience_layout)
		base_layout.addWidget(@experience_history)
	end

	def commit
		$tabs.each do |tab|
			tab.update
		end
	end

	def update
		@experience_total.text = $character.experience.experience
		@build_total.text = $character.experience.build
		@loose_experience.text = $character.experience.loose

		text = ''
		$character.experience.trail.each do |trail|
			text += trail
		end
		@experience_history.text = text

	end

end

class BackstoryWidget < Qt::Widget
	def initialize(parent=nil)
		super(parent)

		@layout = Qt::VBoxLayout.new(self)

		@backstory_text = Qt::TextEdit.new(self)
		@backstory_text.acceptRichText = false
		@backstory_text.tabChangesFocus = true
		@backstory_text.tabStopWidth = 20
		@backstory_text.text= ''

		@backstory_text.connect(SIGNAL(:textChanged)) {
			$character.backstory = @backstory_text.toPlainText
		}

		@layout.addWidget(@backstory_text)
	end

	def update
		@backstory_text.plainText = $character.backstory
	end
end

class BaseWidget < Qt::Widget
	slots 'open()','save()','new()','save_as()','menu_exit()','export()','revert()'
	def initialize(parent=nil)
		super(parent)

		self.windowTitle= 'NERO Character Creator'

		@layout = Qt::VBoxLayout.new(self)

		@menubar = Qt::MenuBar.new(self)
		@file_menu = Qt::Menu.new('&File')

		action_new = Qt::Action.new('&New',self)
		@file_menu.addAction(action_new)
		action_new.connect(SIGNAL(:triggered)) {
			self.new()
		}
		#connect(action_new, SIGNAL('triggered()'),
				  #self, SLOT('new()'))
		action_new.shortcut = Qt::KeySequence.new("Ctrl+N")

		action_open = Qt::Action.new('&Open',self)
		@file_menu.addAction(action_open)
		#connect(action_open, SIGNAL('triggered()'),
				  #self, SLOT('open()'))
		action_open.connect(SIGNAL(:triggered)) {
			self.open()
		}
		action_open.shortcut = Qt::KeySequence.new("Ctrl+O")

		action_revert = Qt::Action.new('Reload from Disk', self)
		@file_menu.addAction(action_revert)
		action_revert.connect(SIGNAL(:triggered)) {
			self.revert()
		}

		action_save = Qt::Action.new('&Save',self)
		@file_menu.addAction(action_save)
		action_save.connect(SIGNAL(:triggered)) {
			self.save()
		}
		#connect(action_save, SIGNAL('triggered()'),
				  #self, SLOT('save()'))
		action_save.shortcut = Qt::KeySequence.new("Ctrl+S")

		action_save_as = Qt::Action.new('Save &As',self)
		@file_menu.addAction(action_save_as)
		action_save_as.connect(SIGNAL(:triggered)) {
			self.save_as()
		}
		#connect(action_save_as, SIGNAL('triggered()'),
				  #self, SLOT('save_as()'))
		action_save_as.shortcut = Qt::KeySequence.new("Ctrl+Shift+S")

		if File.exists?($data_path + 'chapter.ini')
			action_export = Qt::Action.new('&Export as HTML to Desktop',self)
			@file_menu.addAction(action_export)
			action_export.connect(SIGNAL(:triggered)) {
				self.export()
			}
			#connect(action_export, SIGNAL('triggered()'),
					  #self, SLOT('export()'))
		end


		action_exit = Qt::Action.new('E&xit',self)
		@file_menu.addAction(action_exit)
		action_exit.connect(SIGNAL(:triggered)) {
			self.menu_exit()
		}
		#connect(action_exit, SIGNAL('triggered()'),
				  #self, SLOT('menu_exit()'))

		#Experience Menu
		@exp_menu = Qt::Menu.new('&Experience')
		action_set_exp = Qt::Action.new('Set E&xperience',self)
		action_set_build = Qt::Action.new('Set &Build',self)
		action_set_loose = Qt::Action.new('Set Loose Experience',self)
		action_set_level = Qt::Action.new('Set &Level',self)
		action_exp_undo = Qt::Action.new('&Undo',self)
		action_exp_undo.shortcut = Qt::KeySequence.new("Ctrl+Z")
		action_set_exp.connect(SIGNAL(:triggered)) {
			val = Qt::InputDialog::getInteger(nil,'Set Experience','Experience',$character.experience.experience,0,999999999)
			if val != nil
				$character.experience.reset({:experience => val})
				self.commit
			end
		}
		action_set_build.connect(SIGNAL(:triggered)) {
			val = Qt::InputDialog::getInteger(nil,'Set Build','Build',$character.experience.build,15,8419)
			if val != nil
				$character.experience.reset({:build => val})
				self.commit
			end
		}
		action_set_loose.connect(SIGNAL(:triggered)) {
			val = Qt::InputDialog::getInteger(nil,'Set Loose Experience','Loose Experience',$character.experience.loose,0,999999999999)
			if val != nil
				$character.experience.reset({:loose => val})
				self.commit
			end
		}
		action_set_level.connect(SIGNAL(:triggered)) {
			val = Qt::InputDialog::getInteger(nil,'Set Level','Level',$character.experience.level,1,841)
			if val != nil
				$character.experience.reset({:level => val})
				self.commit
			end
		}
		action_exp_undo.connect(SIGNAL(:triggered)) {
			$character.experience.undo
			self.commit
		}
		@exp_menu.addAction action_set_exp
		@exp_menu.addAction action_set_build
		@exp_menu.addAction action_set_level
		@exp_menu.addAction action_exp_undo

		@menubar.addMenu(@file_menu)
		@menubar.addMenu(@exp_menu)

		@layout.addWidget(@menubar)

		$tabs = [InfoWidget.new(self),
		         BuildWidget.new(self),
		         ExperienceWidget.new(self),
		         BackstoryWidget.new(self)]
		@tabbar = Qt::TabWidget.new(self)
		@tabbar.addTab($tabs[0],'Info')
		@tabbar.addTab($tabs[1],'Build')
		@tabbar.addTab($tabs[2],'Experience')
		@tabbar.addTab($tabs[3],'Backstory')

		@layout.addWidget(@tabbar)

		$tabs[0].startup()

		self.new()

		if File.exists? 'ncc.yml'
			$character.load 'ncc.yml'
			$tabs.each do |tab|
				tab.update
			end
		end
		$tabs << AutoSaver.new('ncc.yml')
	end

	# Saves the file over the file most recently saved or opened
	def save()
		$log.debug "Saving"
		return self.save_as(@file)
	end

	def export(file=nil)
		$log.debug "Exporting"
		file = "#{ENV['USERPROFILE']}/Desktop/Tempsheet - #{$character.player_name} (#{$character.name}).html"
		$log.debug "Exporting #{file}"
		begin
			File.open(file,'w') { |f|
				unless $character.to_html.empty?
					f.write($character.to_html)
				else
					$log.debug "export() Character did not generate HTML!"
				end
			}
		rescue
			$log.error "Could not export to file #{file}"
			# TODO: Give the user an error message
		end
	end

	# Save the current character into the passed file
	# If no file is passed, open a dialog to get the file
	def save_as( file = nil )
		$log.debug "Saving As"
		if file == nil
			Qt::FileDialog.new do |fd|
				file = fd.get_save_file_name()
			end
		end
		unless file
			$log.warn "Save As: No filename provided..."
			return
		end
		@file = file

		begin
			File.open(@file,'w') { |f|
				f.write($character.to_s)
			}
		rescue
			$log.error "Could not save to file #{@file}"
			# TODO: Give the user an error message
		end
	end

	# Reset the character
	def new()
		@file = nil
		$character = NERO_Character.new()
		$tabs.each do |tab|
			tab.update
		end
	end

	# Revert to the version of the current file that is on disk
	def revert()
		$log.info "Reverting"
		begin
			return unless @file
			unless $character.load @file
				$log.error "Failed to revert to file: #{@file}"
			end
			$tabs.each do |tab|
				tab.update
			end
		rescue
			$log.error "Failed to revert..."
		end
	end

	# Open a file dialog
	# open that file
	# set @file to that file
	def open()
		$log.info "Opening"
		file = nil
		Qt::FileDialog.new() do |fd|
			file = fd.get_open_file_name
		end
		return unless file
		self.new()
		$log.debug "Opening '#{file}'"
		@file = file

		unless $character.load @file
			$log.error "Failed to load character from #{file}"
			#TODO: Raise an error message for them
		end
		$tabs.each do |tab|
			tab.update
		end
	end

	# called when exit is clicked from the menus
	# TODO: Make this check to see if the file is unsaved and offer to save it.
	def menu_exit()
		exit!()
	end

	def commit
		$tabs.each do |tab|
			tab.update
		end
	end
end

class FormalMagicEffects < Qt::GridLayout

	def initialize(parent=nil,location='Spirit',school_completer=nil)
		super(parent)
		if school_completer == nil
			school_completer = Qt::Completer.new(%w(Earth Celestial Nature))
		end

		restriction_completer = Qt::Completer.new(%w(Unrestricted Restricted Local\ Chapter\ Only LCO))
		restriction_completer.completionMode= Qt::Completer::InlineCompletion

		@location = location

		@effects = (location == 'Spirit') ? $character.spirit_effects : $character.body_effects

		@effect_widgets      = []
		@expire_widgets      = []
		@school_widgets      = []
		@restriction_widgets = []

		self.addWidget(Qt::Label.new("#{@location} Effects:"),
		                        0,0,1,3)
		
		self.addWidget(Qt::Label.new('Effect Name'),1,0)
		self.addWidget(Qt::Label.new('Expires'),1,1)
		self.addWidget(Qt::Label.new('School'),1,2)
		self.addWidget(Qt::Label.new('Restriction'),1,3)
		(0..4).each do |i|
			@effect_widgets << Qt::LineEdit.new('',nil)
			self.addWidget(@effect_widgets[i],i+2,0)

			@effect_widgets[i].connect(SIGNAL(:editingFinished)) {
				self.effects.set_effect(i,@effect_widgets[i].text)
			}

			@expire_widgets << Qt::DateEdit.new(Qt::Date::currentDate(),parent)
			@expire_widgets[i].displayFormat='yyyy/MM/dd'
			@expire_widgets[i].calendarPopup=true
			self.addWidget(@expire_widgets[i],i+2,1)

			@expire_widgets[i].connect(SIGNAL(:editingFinished)) {
				td = @expire_widgets[i].date
				self.effects.set_expiration(i,Date.new(td.year,td.month,td.day))
			}

			@school_widgets << Qt::LineEdit.new('',nil)
			@school_widgets[i].setCompleter(school_completer)
			self.addWidget(@school_widgets[i],i+2,2)

			@school_widgets[i].connect(SIGNAL(:editingFinished)) {
				self.effects.set_school(i,@school_widgets[i].text)
			}

			@restriction_widgets << Qt::LineEdit.new('',nil)
			@restriction_widgets[i].setCompleter(restriction_completer)
			self.addWidget(@restriction_widgets[i],i+2,3)
			
			@restriction_widgets[i].connect(SIGNAL(:editingFinished)) {
				self.effects.set_restriction(i,@restriction_widgets[i].text)
			}
		end
	end

	def effects
		(@location == 'Spirit') ? $character.spirit_effects : $character.body_effects
	end

	def update
		(0..4).each do |i|
			@effect_widgets[i].text= self.effects.get_effect(i)
			if self.effects.get_expiration(i).is_a? String
				exp = self.effects.get_expiration(i).split '-'
				date = Qt::Date.new exp[0].to_i, exp[1].to_i, exp[2].to_i
			else
				exp = self.effects.get_expiration(i)
				date = Qt::Date.new exp.year, exp.month, exp.day
			end
			@expire_widgets[i].date= date
			@school_widgets[i].text = self.effects.get_school i
			@restriction_widgets[i].text = self.effects.get_restriction i
		end
	end
end

class SpellTreeLayout < Qt::GridLayout
	def initialize(parent=nil,tree_type='Primary',base_cost=1)
		super(parent)

		@base_cost = base_cost

		@tree_type = tree_type

		self.setAlignment Qt::AlignHCenter
		self.addWidget(Qt::Label.new("#{@tree_type} Spell Tree"),0,0,1,11)
		@tree = []
		@plus = []
		@minus = []
		(0..8).each do |i|
			@tree[i] = Qt::LineEdit.new('0',nil)
			@tree[i].setMaximumWidth(30)
			@tree[i].setMaxLength(2)
			@tree[i].setAlignment Qt::AlignHCenter
			@tree[i].readOnly = true
			@tree[i].toolTip = "Cost: #{@base_cost * spell_cost(i)}"
			self.addWidget(@tree[i],1,i+(i/3),Qt::AlignCenter)

			@plus[i] = Qt::PushButton.new('+',nil)
			@plus[i].setMinimumWidth(10)
			@plus[i].setMinimumHeight(10)
			@plus[i].setMaximumWidth(20)
			@plus[i].setMaximumHeight(20)

			@minus[i] = Qt::PushButton.new('-',nil)
			@minus[i].setMinimumWidth(10)
			@minus[i].setMinimumHeight(10)
			@minus[i].setMaximumWidth(20)
			@minus[i].setMaximumHeight(20)

			@plus[i].connect(SIGNAL(:clicked)) { self.increment i }
			@minus[i].connect(SIGNAL(:clicked)) { self.decrement i }

			mod_tree_layout = Qt::HBoxLayout.new(nil)
			mod_tree_layout.spacing=0
			mod_tree_layout.addWidget(@minus[i])
			mod_tree_layout.addWidget(@plus[i])

			self.addLayout(mod_tree_layout,2,i+(i/3))
		end
		[3,7].each do |i|
			self.addWidget(Qt::Label.new('/',nil),1,i,Qt::AlignCenter)
		end
	end


private
	def spells_at i
		return @tree[i].text.to_i
	end

	def set_spells_at i, val
		return if val < 0
		@tree[i].text= val.to_s
	end

	def enforce_legality static
		# First traverse down in number:
		(static - 1).downto(0) do |i|
		#(0 .. (static - 1)).each do |j|
      #i = (static - 1) - j
			# turning 44 into 45 -> 55
			if spells_at(i) < spells_at(i+1)
				set_spells_at(i, spells_at(i+1))
			end
			if spells_at(i) < 4 and spells_at(i) == spells_at(i+1)
				set_spells_at(i, spells_at(i)+1)
			end
			if spells_at(i) <= 4 and spells_at(i) > spells_at(i+1)+2
				set_spells_at(i, spells_at(i)-1)
			end
			if spells_at(i) > 4 and spells_at(i) > spells_at(i+1)+1
				set_spells_at(i, spells_at(i)-1)
			end
		end
		(static + 1).upto(8) do |i|
			if spells_at(i-1) < spells_at(i)
				set_spells_at(i, spells_at(i-1))
			end
			if spells_at(i-1) < 4 and spells_at(i-1) == spells_at(i)
				set_spells_at(i, spells_at(i)-1)
			end
			if spells_at(i-1) <= 4 and spells_at(i-1) > spells_at(i) + 2
				set_spells_at(i, spells_at(i-1)-2)
			end
			if spells_at(i-1) > 4 and spells_at(i-1) > spells_at(i) + 1
				set_spells_at(i,spells_at(i-1)-1)
			end
		end

	end

public
	def increment i
		if self.can_add_spells()
			set_spells_at(i, spells_at(i) + 1)
			enforce_legality(i)
			enforce_legality(i)
			self.commit()
		else
			err = Qt::MessageBox.new(nil,'Error Adding Spell','Cannot add spell: Missing some prerequisite.')
			err.show()
		end
	end

	def decrement i
		set_spells_at(i, spells_at(i) - 1)
		enforce_legality(i)
		self.commit()
	end

public
	def update
		$log.debug "SpellTree(#{self.school},#{@tree_type}).update()"
		@tree.each_with_index do |t,i|
			val = $character.build.spell_at(self.school, i+1)
			t.text = val
		end

		self.change_cost_tooltips
	end

	def school
		if @tree_type == 'Primary'
			return $character.primary
		else
			return $character.secondary
		end
	end

	def commit
		school = self.school()
		$character.build.set_tree school, self.tree
		$tabs.each do |tab|
			tab.update
		end
	end

	def tree
		result = []
		(0..8).each { |i| result << spells_at(i) }
		return result
	end

	def change_cost_tooltips
		(0..8).each do |i|
			@tree[i].toolTip = "Cost: #{@base_cost * spell_cost(i)}"
		end
	end

	# Returns the cost of the tree: assumes primary
	# Basically this is meant to be added to the build total
	# if this is a secondary tree
	def tree_cost
		cost = 0
		(0..8).each do |i|
			cost += self.spell_cost(i)*@tree[i]
		end
		return cost
	end

	# Returns true if the character has the proper skills needed
	# to add spells.
	def can_add_spells
		skill = $nero_skills.lookup( "#{self.school()} 1" )
		cskill= Character_Skill.new(skill, {}, 1, $character)

		return cskill.meets_prerequisites?
	end

	
	def spell_cost i
		case $character.character_class.name
		when 'Scholar'
			return scholar_cost(i)
		when 'Templar'
			return (i * 2/3) + 1
		when 'Fighter'
			return scholar_cost(i)*3
		when 'Rogue'
			return 2 * scholar_cost(i)
		else
			return scholar_cost(i)
		end
	end

	def scholar_cost i
		return (i * 1/2) + 1
	end
end

# Run the application
if __FILE__ == $0
	$data_path = "#{Dir.pwd()}/"
	begin
		Dir.chdir(ENV['USERPROFILE'] + "/My Documents")
	rescue
		$log.error "Could not change directory to 'My Documents'"
	end
	$nero_skills = NERO_Skills.new()
	$character = NERO_Character.new()
	$log.info "Starting Corvec's Cool, Creative Character Creator"
	app = Qt::Application.new(ARGV)
	my_widget = BaseWidget.new()
	my_widget.show()
	app.exec
end
