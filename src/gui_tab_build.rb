#!/usr/bin/env ruby



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

		skill_list = self.build_skill_list()
		$log.info "GUI Skill Entry list length: #{skill_list.length}"

		unless ['Line Edit','Text Box','Drop Down','Combo Box'].include? $config.setting('Skill Entry')
			$log.error "Could not interpret Skill Entry setting (#{$config.setting})."
			$config.update_setting('Skill Entry','Text Box')
		end
		case $config.setting('Skill Entry')
		when 'Line Edit','Text Box' then
			@skill_entry = Qt::LineEdit.new(nil)
			skill_completer = Qt::Completer.new(skill_list,nil)
			skill_completer.completionMode= Qt::Completer::UnfilteredPopupCompletion
			@skill_entry.setCompleter(skill_completer)
		when 'Drop Down','Combo Box' then
			@skill_entry = Qt::ComboBox.new(nil)
			@skill_entry.add_items skill_list
		end
		
		
		skill_layout.addWidget(@skill_entry, 1,0,1,2)
		skill_layout.addWidget(Qt::Label.new('Note',nil),2,0)
		@skill_options_entry = Qt::LineEdit.new(nil)
		skill_layout.addWidget(@skill_options_entry,2,1)
		skill_entry_button = Qt::PushButton.new('Add',nil)

		if $config.setting('Skill Entry') != 'Drop Down'
			@skill_entry.connect(SIGNAL(:returnPressed)) {
				self.add_entered_skill()
			}
		end

		skill_entry_button.connect(SIGNAL(:clicked)) {
			self.add_entered_skill()
		}
		@skill_options_entry.connect(SIGNAL(:returnPressed)) {
			self.add_entered_skill()
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
		case $config.setting('Skill Entry')
		when 'Line Edit','Text Box' then
			skill_name = @skill_entry.text
		when 'Drop Down', 'Combo Box' then
			skill_name = @skill_entry.current_text
		end
		if !$character.build.add_skill skill_name, @skill_options_entry.text
			err = Qt::MessageBox.new(nil,'Error Adding Skill',$character.build.get_add_error())
			err.show()
		else
			case $config.setting('Skill Entry')
			when 'Line Edit','Text Box' then
				@skill_entry.text = ''
			when 'Drop Down','Combo Box' then
				@skill_entry.current_index = 0
			end
			@skill_options_entry.text = ''
			@skill_entry.setFocus()
		end
		self.commit() if $character.build.commit?
	end

	def build_skill_list()
		skill_list = $nero_skills.skill_names
		skill_list.insert(0,'')
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
				skill_count_dec.setMinimumWidth($config.setting('Skill Count Min Width').to_i)
				skill_count_dec.setMinimumHeight($config.setting('Skill Count Min Height').to_i)
				skill_count_dec.setMaximumWidth($config.setting('Skill Count Max Width').to_i)
				skill_count_dec.setMaximumHeight($config.setting('Skill Count Max Height').to_i)

				skill_count_dec.connect(SIGNAL(:clicked)) {
					domino = $character.build.legally_delete_skill skill.name, skill.options

					#$log.debug "Domino: #{domino}"

					if $character.build.commit? #domino or ($character.build.count(skill.name, skill.options) <= 0)
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
						err = Qt::MessageBox.new(nil,'Error Incrementing Skill',$character.build.get_add_error())
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

				@grid.addWidget(skill_count_frame,i,0)
			else
				remove_skill_button = Qt::PushButton.new('X',nil)
				remove_skill_button.connect(SIGNAL(:clicked)) {
					$character.build.legally_delete_skill skill.name, skill.options
					self.commit() if $character.build.commit?
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

		self.verticalScrollBar.sliderPosition = slider_position
	end
	def commit
		$tabs.each do |tab|
			tab.update
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
		@cost_label = Qt::Label.new('(0)',nil)
		self.addWidget(@cost_label,1,11,Qt::AlignCenter)
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
			$log.error 'Cannot add spell: Missing some prerequisite.'
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

		@cost_label.text = "(#{self.tree_cost()})"

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
		unless $character.build.set_tree school, self.tree
			self.update
			err = Qt::MessageBox.new(nil,'Error Adding Spell',$character.build.get_add_error())
			err.show()
		else
			$tabs.each do |tab|
				tab.update
			end
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
			cost += self.spell_cost(i)*@tree[i].text.to_i
		end
		cost *= 2 if @tree_type != 'Primary'
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
