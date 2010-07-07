#!/usr/bin/env ruby

require 'gui_tab_info.rb'
require 'gui_tab_build.rb'
require 'gui_tab_experience.rb'
require 'gui_tab_backstory.rb'


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

class BaseWidget < Qt::Widget
	slots 'open()','save()','new()','save_as()','menu_exit()','export()','revert()'
	def initialize(parent=nil)
		super(parent)

		self.windowTitle= $config.setting('Title')

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

		unless $config.setting('Chapter').nil?
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
			if $character.build.commit?
				$tabs.each do |tab|
					tab.update
				end
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
			err = Qt::MessageBox.new(nil,"Error Exporting","Could not export to file #{file}")
			err.show()
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
			err = Qt::MessageBox.new(nil,"Error Saving","Could not save to file #{@file}")
			err.show()
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
				err = Qt::MessageBox.new(nil,"Error Reverting","Could not revert to file #{@file}")
				err.show()
			end
			$tabs.each do |tab|
				tab.update
			end
		rescue
			$log.error "Failed to revert..."
			err = Qt::MessageBox.new(nil,"Error Reverting","Could not revert to file #{@file}")
			err.show()
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
			err = Qt::MessageBox.new(nil,"Error Loading","Could not load from file #{@file}")
			err.show()
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
