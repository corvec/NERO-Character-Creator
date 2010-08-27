#!/usr/bin/env ruby


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

