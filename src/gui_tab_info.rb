#!/usr/bin/env


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
