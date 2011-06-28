#!/usr/bin/env ruby

require 'gui_tab_info.rb'
require 'gui_tab_build.rb'
require 'gui_tab_experience.rb'
require 'gui_tab_backstory.rb'
require 'gui_config.rb'


# If added to the list of tabs, this will automatically save to the passed file every time the tabs are all updated.
class AutoSaver
	def initialize(filename)
		@filename = filename
	end

	def update
		if $config.setting('Enable Autosave')
			begin
				File.open(@filename,'w') do |f|
					f.write($character.to_yaml)
				end
			rescue Exception => e
				$log.error "Failed to autosave"
			end
		end
	end
end

class BaseWidget < Qt::Widget
	#slots 'open()','save()','new()','save_as()','menu_exit()','export()','revert()'
	def initialize(parent=nil)
		super(parent)

		self.windowTitle= $config.setting('Title')

		@layout = Qt::VBoxLayout.new(self)

		@menubar = Qt::MenuBar.new(self)
		@file_menu = Qt::Menu.new('&File')

		action_new = Qt::Action.new('&New',self)
		action_open = Qt::Action.new('&Open',self)
		action_revert = Qt::Action.new('Reload from Disk', self)
		action_save = Qt::Action.new('&Save',self)
		action_save_as = Qt::Action.new('Save &As',self)
		action_new.shortcut = Qt::KeySequence.new("Ctrl+N")
		action_open.shortcut = Qt::KeySequence.new("Ctrl+O")
		action_save.shortcut = Qt::KeySequence.new("Ctrl+S")
		action_save_as.shortcut = Qt::KeySequence.new("Ctrl+Shift+S")


		@file_menu.addAction(action_new)
		action_new.connect(SIGNAL(:triggered)) {
			self.new()
		}
		#connect(action_new, SIGNAL('triggered()'),
				  #self, SLOT('new()'))

		@file_menu.addAction(action_open)
		#connect(action_open, SIGNAL('triggered()'),
				  #self, SLOT('open()'))
		action_open.connect(SIGNAL(:triggered)) {
			self.open()
		}

		@file_menu.addAction(action_revert)
		action_revert.connect(SIGNAL(:triggered)) {
			self.revert()
		}

		@file_menu.addAction(action_save)
		action_save.connect(SIGNAL(:triggered)) {
			self.save()
		}
		#connect(action_save, SIGNAL('triggered()'),
				  #self, SLOT('save()'))

		@file_menu.addAction(action_save_as)
		action_save_as.connect(SIGNAL(:triggered)) {
			self.save_as()
		}
		#connect(action_save_as, SIGNAL('triggered()'),
				  #self, SLOT('save_as()'))

		unless $config.setting('Chapter').nil?
			action_export = Qt::Action.new('&Export as HTML to Desktop',self)
			@file_menu.addAction(action_export)
			action_export.connect(SIGNAL(:triggered)) {
				self.export()
			}
			action_export.shortcut = Qt::KeySequence.new("Ctrl+E")
			#connect(action_export, SIGNAL('triggered()'),
					  #self, SLOT('export()'))
		end

		unless $config.setting('One Line Export').nil?
			action_one_line_export = Qt::Action.new("Generate One Line Export", self)
			@file_menu.addAction(action_one_line_export)
			action_one_line_export.connect(SIGNAL(:triggered)) {
				self.one_line_export()
			}
			action_one_line_export.shortcut = Qt::KeySequence.new("Ctrl+T")
		end


		action_exit = Qt::Action.new('E&xit',self)
		@file_menu.addAction(action_exit)
		action_exit.connect(SIGNAL(:triggered)) {
			self.menu_exit()
		}
		
		#Experience Menu
		@exp_menu = Qt::Menu.new('&Experience')
		action_set_exp = Qt::Action.new('Set E&xperience',self)
		action_set_build = Qt::Action.new('Set &Build',self)
		action_set_loose = Qt::Action.new('Set Loose Experience',self)
		action_set_level = Qt::Action.new('Set &Level',self)
		action_exp_undo = Qt::Action.new('&Delete Last Entry',self)
		action_exp_undo.shortcut = Qt::KeySequence.new("Ctrl+D")
		action_set_exp.connect(SIGNAL(:triggered)) {
			qt_okay = Qt::Boolean.new()
			val = Qt::InputDialog::getInteger(nil,'Set Experience','Experience',$character.experience.experience,0,999999999,1,qt_okay)
			if qt_okay.value
				$character.experience.reset({:experience => val})
				self.commit
			end
		}
		action_set_build.connect(SIGNAL(:triggered)) {
			qt_okay = Qt::Boolean.new()
			val = Qt::InputDialog::getInteger(nil,'Set Build','Build',$character.experience.build,15,8419,1,qt_okay)
			if qt_okay.value
				$character.experience.reset({:build => val})
				self.commit
			end
		}
		action_set_loose.connect(SIGNAL(:triggered)) {
			qt_okay = Qt::Boolean.new()
			val = Qt::InputDialog::getInteger(nil,'Set Loose Experience','Loose Experience',$character.experience.loose,1,0,999999999999,1,qt_okay)
			if qt_okay.value
				$character.experience.reset({:loose => val})
				self.commit
			end
		}
		action_set_level.connect(SIGNAL(:triggered)) {
			qt_okay = Qt::Boolean.new()
			val = Qt::InputDialog::getInteger(nil,'Set Level','Level',$character.experience.level,1,841,1,qt_okay)
			if qt_okay.value
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

		#Options Menu
		@opt_menu = Qt::Menu.new('&Options')
		action_open_config = Qt::Action.new('Open Options File',self)
		action_open_config.connect(SIGNAL(:triggered)) {
			system("#{$config.setting('Editor')} #{$config.setting('Working Directory')}/ncc.ini")
		}
		#@opt_menu.addAction action_open_config
		action_config_window = Qt::Action.new('&Settings',self)
		action_config_window.connect(SIGNAL(:triggered)) {
			config_window = ConfigWidget.new(self)
			config_window.show()
		}
		@opt_menu.addAction action_config_window

		#Help Menu
		@help_menu = Qt::Menu.new('&Help')
		action_help = Qt::Action.new('&Help',self)
		action_about = Qt::Action.new('&About',self)
		action_help.connect(SIGNAL(:triggered)) {
			system("hh \"#{$config.setting('Working Directory')}/ncc.chm\"")
		}
		action_html_help = Qt::Action.new('HT&ML Help',self)
		action_html_help.connect(SIGNAL(:triggered)) {
			Qt::DesktopServices.open_url(Qt::Url.new("file:///#{$config.setting('Working Directory').gsub(' ','%20')}/help/help.htm"))
		}
		action_about.connect(SIGNAL(:triggered)) {
			dlg = Qt::Dialog.new(self)
			dlg.windowTitle = "About NERO Character Creator"

			widgets = []
			widgets << Qt::Label.new('<b><font size="14">NERO Character Creator</font></b>',nil)
			widgets.last.alignment = Qt::AlignCenter
			#widgets.last.textFormat = Qt::RichText
			widgets << Qt::Label.new('Version 0.9.7 (Released 2011 March 29)',nil)
			widgets.last.alignment = Qt::AlignCenter
			widgets << Qt::Label.new('by Corey T Kump',nil)
			widgets.last.alignment = Qt::AlignCenter
			widgets << Qt::Label.new('For the latest version, visit <a href="http://nero.sf.net">the Sourceforge page</a>.',nil)
			widgets.last.openExternalLinks = true
			widgets << Qt::Label.new('For discussion, questions, or support, visit <a href="http://neroindy.com/smf_forum/index.php?topic=1437.0">the thread on neroindy.com</a>.',nil)
			widgets.last.openExternalLinks = true
			widgets.last.openExternalLinks = true
			widgets << Qt::Label.new('Or email <a href="mailto:Corey.Kump@gmail.com?subject=NERO Character Creator">the author</a> with "NERO Character Creator" in the subject line.',nil)
			widgets.last.openExternalLinks = true

			layout = Qt::VBoxLayout.new(dlg)
			widgets.each do |w|
				layout.addWidget(w)
			end
			dlg.show()
		}
		@help_menu.addAction action_help
		@help_menu.addAction action_html_help
		@help_menu.addAction action_about


		@menubar.addMenu(@file_menu)
		@menubar.addMenu(@exp_menu)
		@menubar.addMenu(@opt_menu)
		@menubar.addMenu(@help_menu)

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

		if $config.setting('Autosave')
			if File.exists? $config.setting('Autosave')
				$character.load $config.setting('Autosave')
				if $character.build.commit?
					$tabs.each do |tab|
						tab.update
					end
				end
			end
			$tabs << AutoSaver.new($config.setting('Autosave'))
		end
	end

	# Saves the file over the file most recently saved or opened
	def save()
		$log.debug "Saving"
		return self.save_as(@file)
	end

	def one_line_export()
		$log.debug "Generating One Line Export..."
		export = "#{$character.name},#{$character.race},#{$character.character_class},#{$character.experience.build},#{$character.calculate_body.to_i},#{$character.primary}"

		export = ''
		$character.build.skills.each do |skill|
			if skill.skill.limit != 1 or skill.skill.options.length > 0
				export += "@"
				if skill.skill.limit != 1
					export += "#{skill.count.to_s}x "
				end
				export += "#{skill.to_s}"
				#unless skill.options.empty?
				#	export += skill.options.inspect.gsub('"','')
				#end
			else
				export += "@#{skill.to_s}"
			end
		end
		['Earth','Celestial'].each do |school|
			if $character.build.spell_at(school,1) > 0 then
				export += "@"
				1.upto(9) do |level|
					num = $character.build.spell_at(school,level)
					export += "#{$character.build.spell_at(school,level)} "
					if level == 3 or level == 6 then
						export += "/ "
					end
				end
				export += "#{($character.primary == school) ? 'Primary' : 'Secondary'} school"
			end
		end
		export.sub!('@','')
		export.sub!($character.primary,"Primary") # Formal Magic (Earth) -> Formal Magic (Primary)
		export.sub!($character.secondary,"Secondary")
		$log.info export
		Qt::Application.clipboard.text= export
	end

	def export(file = nil)
		$log.debug "Exporting"
		file = "#{$config.setting('Export')}/Tempsheet - #{$character.player_name} (#{$character.name}).html" if file.nil?
		$log.debug "Exporting #{file}"
		begin
			File.open(file,'w') do |f|
				unless $character.to_html.empty?
					f.write($character.to_html)
				else
					$log.debug "export() Character did not generate HTML!"
				end
			end
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
				fd.defaultSuffix = 'yml'
				file = fd.get_save_file_name(nil,'Save NERO Character Sheet',$config.setting('Save Directory').to_s,'YAML Files (*.yml);;All Files (*)' )
			end
		end
		unless file
			$log.warn "Save As: No filename provided..."
			return nil
		end
		@file = file

		begin
			File.open(@file,'w') do |f|
				f.write($character.to_yaml)
			end
		rescue Exception => e
			$log.error "Could not save to file #{@file}"
			$log.error e.inspect
			$log.error e.backtrace
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
			file = fd.get_open_file_name(nil, 'Open NERO Character Sheet', $config.setting('Save Directory').to_s, 'YAML Files (*.yml);;All Files (*)')
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

