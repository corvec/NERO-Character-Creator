#!/usr/bin/env ruby

class AbilitiesWidget < Qt::Widget
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
		@build_total = Qt::Label.new($character.experience.Build.to_s,nil)
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

		skill_list = self.build_skill_list()
		$log.info "GUI Skill Entry list length: #{skill_list.length}"

		unless ['Line Edit','Text Box','Drop Down','Combo Box'].include? $config.setting('Skill Entry')
			$log.error "Could not interpret Skill Entry setting (#{$config.setting})."
			$config.update_setting('Skill Entry','Drop Down')
		end

		case $config.setting('Skill Entry')
		when 'Line Edit','Text Box' then
			skill_layout = Qt::GridLayout.new(skill_frame)
			skill_layout.addWidget(Qt::Label.new('Learn a new Skill:',nil),0,0,1,3)

			@skill_entry = Qt::LineEdit.new(nil)
			skill_completer = Qt::Completer.new(skill_list,nil)
			skill_completer.completionMode= Qt::Completer::UnfilteredPopupCompletion
			@skill_entry.setCompleter(skill_completer)

			skill_layout.addWidget(@skill_entry, 1,0,1,2)
			skill_layout.addWidget(Qt::Label.new('Note',nil),2,0)
			@skill_options_entry = Qt::LineEdit.new(nil)
			skill_layout.addWidget(@skill_options_entry,2,1)
			skill_entry_button = Qt::PushButton.new('Add',nil)

			@skill_entry.connect(SIGNAL(:returnPressed)) {
				self.add_entered_skill()
			}

			skill_entry_button.connect(SIGNAL(:clicked)) {
				self.add_entered_skill()
			}

			@skill_options_entry.connect(SIGNAL(:returnPressed)) {
				self.add_entered_skill()
			}
			skill_layout.addWidget(skill_entry_button, 1,2,2,1)

			add_skill_layout.addWidget(skill_frame,0,0)
		when 'Drop Down','Combo Box' then
			skill_entry_layout = Qt::VBoxLayout.new(skill_frame)

			skill_options_frame = Qt::Frame.new(self)
			skill_options_layout = Qt::HBoxLayout.new(skill_options_frame)

			spacer_label = Qt::Label.new(' ',nil)
			skill_options_layout.addWidget(spacer_label)

			option_widgets = [spacer_label] # So they can easily be removed
			@option_entries = {} # To lookup, so they can be stored

			@skill_entry = Qt::ComboBox.new(nil)
			@skill_entry.add_items skill_list


			# This allows pressing Enter to add the skill, but disables pressing letters to select the option
			#@skill_entry.editable = true
			#@skill_entry.lineEdit.readOnly = true
			#@skill_entry.lineEdit.connect(SIGNAL(:returnPressed)) do
				#self.add_entered_skill()
			#end

			@skill_entry.connect(SIGNAL('currentIndexChanged(int)')) {
				skill = NERO_Skill.lookup(@skill_entry.current_text)

				option_widgets.each do |o_widget|
					o_widget.hide
					skill_options_layout.removeWidget(o_widget)
				end
				option_widgets.clear
				@option_entries.clear

				if skill.nil?
					skill_entry_button.enabled = false
					spacer_label = Qt::Label.new(' ',nil)
					option_widgets << spacer_label
					skill_options_layout.addWidget(spacer_label)
				elsif skill.options.length == 0
					skill_entry_button.enabled = true
					spacer_label = Qt::Label.new(' ',nil)
					option_widgets << spacer_label
					skill_options_layout.addWidget(spacer_label)
				else
					skill_entry_button.enabled = true
					skill.options.each_with_index do |o,i|
						o_label = Qt::Label.new(o,nil)
						#If this has a specific set of entries
						valid_values = $character.build.valid_option_values(o)
						if valid_values.nil?
							o_entry = Qt::LineEdit.new(nil)
							o_entry.connect(SIGNAL(:returnPressed)) do
								self.add_entered_skill()
							end
						else
							o_entry = Qt::ComboBox.new(nil)
							o_entry.add_items valid_values
							# This allows pressing Enter to add the skill, but disables pressing letters to select the option
							#o_entry.editable = true
							#o_entry.lineEdit.readOnly = true
							#o_entry.lineEdit.connect(SIGNAL(:returnPressed)) do
								#self.add_entered_skill()
							#end
						end

						option_widgets << o_label
						option_widgets << o_entry

						@option_entries[o] = o_entry

						skill_options_layout.addWidget(o_label)
						skill_options_layout.addWidget(o_entry)

						if i == 0
							Qt::Widget.set_tab_order(@skill_entry,o_entry)
						else
							Qt::Widget.set_tab_order(@option_entries[skill.options[i-1]],o_entry)
						end
					end
					#@option_widgets[1].setFocus
				end
				skill_options_frame.updateGeometry()
				skill_options_frame.repaint()
			}

			skill_entry_button = Qt::PushButton.new('Add',nil)
			skill_entry_button.default = true
			skill_entry_button.enabled = false

			skill_entry_button.connect(SIGNAL(:clicked)) {
				self.add_entered_skill()
			}

			skill_entry_layout.addWidget(Qt::Label.new('Learn a new Skill:',nil))
			skill_entry_layout.addWidget(@skill_entry)
			skill_entry_layout.addWidget(skill_options_frame)
			skill_entry_layout.addWidget(skill_entry_button)

			add_skill_layout.addWidget(skill_frame,0,0)
		end

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

		@saved_race = $character.race.to_s
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

		if $character.race.to_s != @saved_race
			$log.info "Updating skill list because of race change"
			@saved_race = $character.race.to_s
			@skill_entry.clear()
			@skill_entry.add_items NERO_Skill.list
		end

		@skill_list.update
	end
end

class SkillsWidget < Qt::ScrollArea
	def initialize(build_widget,parent=nil)
		super(parent)
		@build_widget = build_widget
		self.update()
	end

	def update()
		slider_position = self.verticalScrollBar.sliderPosition
		old_frame = self.takeWidget()
		old_frame.deleteLater if old_frame != nil
		@grid = Qt::GridLayout.new(nil) #the old grid should automatically be destroyed

		@abilities = $character.race.abilities
		ability_count = @abilities.size
		@abilities.each_with_index do |ability, i|
			vert_pos = i

			skill_name_label = Qt::Label.new("<i>#{ability.to_s}</i>",nil)
			skill_name_label.setMinimumWidth(200)
			@grid.addWidget(skill_name_label,vert_pos,1)
		end


		@skills = $character.build.skills
		@skills.each_with_index do |skill,i|
			vert_pos = i + ability_count # Vertical Position in the grid
			skill_name_label = Qt::Label.new(skill.to_s,nil)
			skill_name_label.setMinimumWidth(200)
			@grid.addWidget(skill_name_label,vert_pos,1)
			skill_cost_label = Qt::Label.new(skill.cost().to_s,nil)
			@grid.addWidget(skill_cost_label,vert_pos,3)
			if skill.skill.limit != 1
				skill_count_frame = Qt::Frame.new(self)
				skill_count_layout = Qt::GridLayout.new(skill_count_frame)

				skill_count_label = Qt::Label.new("#{skill.count.to_s}X",nil)
				skill_count_layout.addWidget(skill_count_label,0,0,1,2)

				skill_count_dec = Qt::PushButton.new('-',nil)
				skill_count_dec.setMinimumWidth($config.setting('Skill Count Min Width').to_i)
				skill_count_dec.setMinimumHeight($config.setting('Skill Count Min Height').to_i)
				skill_count_dec.setMaximumWidth($config.setting('Skill Count Max Width').to_i)
				skill_count_dec.setMaximumHeight($config.setting('Skill Count Max Height').to_i)

				skill_count_dec.connect(SIGNAL(:clicked)) {
					domino = $character.build.legally_delete_skill skill.to_s, skill.options

					#$log.debug "Domino: #{domino}"

					if $character.build.commit? #domino or ($character.build.count(skill.to_s, skill.options) <= 0)
						self.commit
					else
						skill_count_label.text = "#{skill.count.to_s}X"
						skill_cost_label.text = skill.cost().to_s
						@build_widget.update_banner()
					end
				}

				skill_count_inc = Qt::PushButton.new('+',nil)
				skill_count_inc.setMinimumWidth($config.setting('Skill Count Min Width').to_i)
				skill_count_inc.setMinimumHeight($config.setting('Skill Count Min Height').to_i)
				skill_count_inc.setMaximumWidth($config.setting('Skill Count Max Width').to_i)
				skill_count_inc.setMaximumHeight($config.setting('Skill Count Max Height').to_i)

				skill_count_inc.connect(SIGNAL(:clicked)) {
					unless $character.build.add_skill(skill.skill,skill.options)
						err = Qt::MessageBox.new(nil,'Error Incrementing Skill',$character.build.add_error)
						err.show()
					end
					if $character.build.commit?
						self.commit
					else
						skill_count_label.text = "#{skill.count.to_s}X"
						skill_cost_label.text = skill.cost().to_s
						@build_widget.update_banner
					end
				}

				skill_count_layout.addWidget(skill_count_dec,1,0)
				skill_count_layout.addWidget(skill_count_inc,1,1)

				@grid.addWidget(skill_count_frame,vert_pos,0)
			else
				remove_skill_button = Qt::PushButton.new('X',nil)
				remove_skill_button.connect(SIGNAL(:clicked)) {
					$character.build.legally_delete_skill skill.to_s, skill.options
					self.commit() if $character.build.commit?
				}
				@grid.addWidget(remove_skill_button,vert_pos,0)
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

				@grid.addWidget(options_frame,vert_pos,2)
			end
		end
		@frame = Qt::Frame.new()
		@frame.setLayout(@grid)
		self.setWidget(@frame)

		self.verticalScrollBar.sliderPosition = slider_position
	end
	def commit
		$tabs.each do |tab|
			tab.update
		end
	end
end
