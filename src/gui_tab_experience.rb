#!/usr/bin/env ruby


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
		# 1 Day
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
		# 2 Day
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
		# Mini Mod
		add_event_layout.addWidget(Qt::Label.new('Mini Mod',nil),4,0)
		@add_event_mm_no_maxout = Qt::PushButton.new('No Maxout',nil)
		@add_event_mm_no_maxout.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_pc_event(
				@add_event_name.text, Date.new(td.year,td.month,td.day), 0.5, false)
			self.commit()
		}
		add_event_layout.addWidget(@add_event_mm_no_maxout,4,1)
		@add_event_mm_maxout = Qt::PushButton.new('Maxout',nil)
		@add_event_mm_maxout.connect(SIGNAL(:clicked)) {
			td = @add_event_date.date
			$character.experience.add_pc_event(
				@add_event_name.text, Date.new(td.year,td.month,td.day), 0.5, true)
			self.commit()
		}
		add_event_layout.addWidget(@add_event_mm_maxout,4,2)


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
		@custom_number.setMaxLength(4)
		@custom_number.setMaximumWidth(30)
		add_custom_layout.addWidget(@custom_number)
		add_custom_layout.addWidget(Qt::Label.new('Blanket'))
		@custom_times = Qt::LineEdit.new('1')
		@custom_times.setMaxLength(4)
		@custom_times.setMaximumWidth(30)
		add_custom_layout.addWidget(@custom_times)
		add_custom_layout.addWidget(Qt::Label.new('times.'))
		@custom_add_button = Qt::PushButton.new('Submit')
		@custom_number.connect(SIGNAL(:returnPressed)) {
			$character.experience.add_custom @custom_number.text.to_f, @custom_times.text.to_i
			self.commit
		}
		@custom_times.connect(SIGNAL(:returnPressed)) {
			$character.experience.add_custom @custom_number.text.to_f, @custom_times.text.to_i
			self.commit
		}
		@custom_add_button.connect(SIGNAL(:clicked)) {
			$character.experience.add_custom @custom_number.text.to_f, @custom_times.text.to_i
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
		slider_position = @experience_history.verticalScrollBar.sliderPosition
		@experience_total.text = $character.experience.experience
		@build_total.text = $character.experience.build
		@loose_experience.text = $character.experience.loose

		text = ''
		$character.experience.trail.each do |trail|
			text += trail
		end
		@experience_history.text = text
		@experience_history.verticalScrollBar.sliderPosition = slider_position
	end

end

