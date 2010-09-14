#!/usr/bin/env ruby

class ConfigWidget < Qt::Dialog
	def initialize(parent=nil)
		super(parent)

		self.windowTitle= "#{$config.setting('Title')} Settings"

		self.build_input_widgets()

		@layout = Qt::VBoxLayout.new(self)

		@tabs = [ConfigGeneral.new(@inputs,self),
		         ConfigGameData.new(@inputs,self),
		         ConfigLogs.new(@inputs,self),
		         ConfigUI.new(@inputs,self)]

		@tabbar = Qt::TabWidget.new(self)
		@tabbar.addTab(@tabs[0],'General')
		@tabbar.addTab(@tabs[1],'Game Data')
		@tabbar.addTab(@tabs[2],'Logs')
		@tabbar.addTab(@tabs[3],'UI')

		@layout.addWidget(@tabbar)


		button_ok = Qt::PushButton.new('OK',nil)
		button_apply = Qt::PushButton.new('Apply',nil)
		button_cancel = Qt::PushButton.new('Cancel',nil)

		button_ok.connect(SIGNAL(:clicked)) {
			self.save_configuration()
			self.accept()
		}
		button_apply.connect(SIGNAL(:clicked)) {
			self.save_configuration()
		}
		button_cancel.connect(SIGNAL(:clicked)) {
			self.reject()
		}

		close_frame = Qt::Frame.new(self)
		close_frame_layout = Qt::HBoxLayout.new(close_frame)
		close_frame_layout.addWidget(button_ok)
		close_frame_layout.addWidget(button_apply)
		close_frame_layout.addWidget(button_cancel)
		@layout.addWidget(close_frame)


		#$tabs[0].startup()

		self.new()
	end

	def build_input_widgets

		@inputs = {}

		@line_edits = ['Title','Skill Data','Working Directory','Autosave','Save Directory','Export','Log Output','Log Size','Log Count']
		@line_edits.each do |setting|
			@inputs[setting] = Qt::LineEdit.new($config.setting(setting).to_s,nil)
		end

		@check_boxes = {'Satisfy Prerequisites' => 'Automatically Purchase Prerequisite Skills',
						'Enforce Build' => 'Enforce Build Totals',
						'Enable Autosave' => 'Enable Autosave',
						'Enable Logging' => 'Enable Logging'}

		@check_boxes.each do |setting,label|
			@inputs[setting] = Qt::CheckBox.new(label,nil)
			@inputs[setting].checked = $config.setting(setting)
		end

		@inputs['Goblins'] = Qt::CheckBox.new('Concurrent Goblins',nil)
		@inputs['Goblins'].checked = ($config.setting('Goblins') == 'Group')

		@inputs['Modules'] = Qt::ListWidget.new(nil)
		num = 1
		until $config.setting("Module #{num}").nil?
			@inputs['Modules'].add_item($config.setting)
			num += 1
		end

		@inputs['Log Threshold'] = Qt::ComboBox.new(nil)
		threshold_list = ['Fatal Errors','Errors','Warnings','Information','Debug Data']
		@inputs['Log Threshold'].add_items(threshold_list)
		@inputs['Log Threshold'].current_index = threshold_list.index $config.setting('Log Threshold')

		entry_list = ['Drop Down','Text Box']
		@inputs['Race Entry'] = Qt::ComboBox.new(nil)
		@inputs['Race Entry'].add_items(entry_list)
		@inputs['Race Entry'].current_index = entry_list.index $config.setting('Race Entry') if entry_list.include? $config.setting('Race Entry')
		@inputs['Class Entry'] = Qt::ComboBox.new(nil)
		@inputs['Class Entry'].add_items(entry_list)
		@inputs['Class Entry'].current_index = entry_list.index $config.setting('Class Entry') if entry_list.include? $config.setting('Class Entry')
		@inputs['Skill Entry'] = Qt::ComboBox.new(nil)
		@inputs['Skill Entry'].add_items(entry_list)
		@inputs['Skill Entry'].current_index = entry_list.index $config.setting('Skill Entry') if entry_list.include? $config.setting('Skill Entry')
	end

	def save_configuration
		$log.debug "GUI_Config.save_configuration()"
		data = {}
		@line_edits.each do |setting|
			data[setting] = @inputs[setting].text
		end

		data['Log Size'] = data['Log Size'].to_i
		data['Log Count'] = data['Log Count'].to_i

		@check_boxes.each_key do |setting|
			data[setting] = @inputs[setting].checked?
		end

		data['Goblins'] = @inputs['Goblins'].checked? ? 'Group' : 'Individual'

		data['Log Threshold'] = @inputs['Log Threshold'].current_text

		data['Race Entry'] = @inputs['Race Entry'].current_text

		data['Class Entry'] = @inputs['Class Entry'].current_text

		data['Skill Entry'] = @inputs['Skill Entry'].current_text

		(0...@inputs['Modules'].count).each do |i|
			data["Module #{i+1}"] = @inputs['Modules'].item(i).text
		end

		# Update config object
		data.each do |setting, val|
			$config.update_setting(setting,val)
		end

		# Commit to file
		unless $config.commit_settings()
			err = Qt::MessageBox.new(nil,"Error Saving Configuration","Could not save to configuration file.  You may not have permissions to write to the program directory.  You can circumvent this issue by copying the program directory into your local documents folder and pointing your shortcut there.")
			err.show()
		end
	end


end

class ConfigGeneral < Qt::Widget
	def initialize(inputs, parent=nil)
		super(parent)

		@inputs = inputs

		@layout = Qt::GridLayout.new(self)
		@layout.add_widget(Qt::Label.new("Program Title:",nil),0,0)
		@layout.add_widget(@inputs['Title'],0,1)
		@layout.add_widget(@inputs['Goblins'],1,0,1,2)
		@layout.add_widget(@inputs['Satisfy Prerequisites'],2,0,1,2)
		@layout.add_widget(@inputs['Enforce Build'],3,0,1,2)
		
		@layout.add_widget(Qt::Label.new('',nil),20,0)
	end
end

class ConfigGameData < Qt::Widget
	def initialize(inputs, parent=nil)
		super(parent)

		@inputs = inputs

		remove_module_button = Qt::PushButton.new('Remove Selected',nil)
		restore_list_button  = Qt::PushButton.new('Restore List',nil)
		clear_list_button    = Qt::PushButton.new('Clear List',nil)
		add_module_button    = Qt::PushButton.new("Add Module",nil)
		new_module_lineedit  = Qt::LineEdit.new(nil)

		remove_module_button.connect(SIGNAL(:clicked)) {
			if @inputs['Modules'].current_row.is_a? Integer
				@inputs['Modules'].take_item(@inputs['Modules'].current_row)
			end
		}
		restore_list_button.connect(SIGNAL(:clicked)) {
			@inputs['Modules'].clear
			num = 1
			until $config.setting("Module #{num}").nil?
				@inputs['Modules'].add_item($config.setting)
				num += 1
			end
		}
		clear_list_button.connect(SIGNAL(:clicked)) {
			@inputs['Modules'].clear
		}
		add_module_button.connect(SIGNAL(:clicked)) {
			if new_module_lineedit.text != ''
				@inputs['Modules'].add_item(new_module_lineedit.text)
				new_module_lineedit.clear()
			end
		}



		@layout = Qt::GridLayout.new(self)

		@layout.add_widget(Qt::Label.new('Game Data Filename',nil),0,0)
		@layout.add_widget(@inputs['Skill Data'],0,1)
		@layout.add_widget(BrowseButton.new(@inputs['Skill Data'],false,@inputs['Working Directory']),0,2)

		@layout.add_widget(Qt::Label.new('Game Data Directory',nil),1,0)
		@layout.add_widget(@inputs['Working Directory'],1,1)
		@layout.add_widget(BrowseButton.new(@inputs['Working Directory'],true),1,2)

		@layout.add_widget(@inputs['Enable Autosave'],2,0,1,3)

		@layout.add_widget(Qt::Label.new('Autosave Filename',nil),3,0)
		@layout.add_widget(@inputs['Autosave'],3,1)
		@layout.add_widget(BrowseButton.new(@inputs['Autosave'],false,@inputs['Save Directory']),3,2)

		@layout.add_widget(Qt::Label.new('Save Directory',nil),4,0)
		@layout.add_widget(@inputs['Save Directory'],4,1)
		@layout.add_widget(BrowseButton.new(@inputs['Save Directory'],true),4,2)
		
		@layout.add_widget(Qt::Label.new('Export Directory',nil),5,0)
		@layout.add_widget(@inputs['Export'],5,1)
		@layout.add_widget(BrowseButton.new(@inputs['Export'],true),5,2)

		@layout.add_widget(Qt::Label.new('<b>Modules</b>',nil),6,0)
		@layout.add_widget(@inputs['Modules'],7,1,3,1)
		@layout.add_widget(remove_module_button,7,0)
		@layout.add_widget(restore_list_button,8,0)
		@layout.add_widget(clear_list_button,9,0)

		@layout.add_widget(Qt::Label.new('<b>Add Module</b>'),12,1)
		pt_frame = Qt::Frame.new(self)
		pt_frame.frameShadow = Qt::Frame::Raised
		pt_frame.frameShape = Qt::Frame::Box
		pt_layout = Qt::GridLayout.new(pt_frame)
		pt_layout.add_widget(new_module_lineedit,0,0)
		pt_layout.add_widget(BrowseButton.new(new_module_lineedit,false,@inputs['Working Directory']),0,1)
		pt_layout.add_widget(add_module_button,1,0,1,2)
		@layout.add_widget(pt_frame,13,1)

	end
end


class ConfigLogs < Qt::Widget
	def initialize(inputs,parent=nil)
		super(parent)
		@inputs = inputs

		@layout = Qt::GridLayout.new(self)

		@layout.add_widget(@inputs['Enable Logging'],0,0,1,3)

		@layout.add_widget(Qt::Label.new('Log Filename',nil),1,0)
		@layout.add_widget(@inputs['Log Output'],1,1)
		@layout.add_widget(BrowseButton.new(@inputs['Log Output'],false,@inputs['Working Directory']),1,2)

		@layout.add_widget(Qt::Label.new('Max Size (KB)',nil),2,0)
		@layout.add_widget(@inputs['Log Size'],2,1)

		@layout.add_widget(Qt::Label.new('Max Number of Files',nil),3,0)
		@layout.add_widget(@inputs['Log Count'],3,1)

		@layout.add_widget(Qt::Label.new('Logging Threshold',nil),4,0)
		@layout.add_widget(@inputs['Log Threshold'],4,1)

		#Spacer
		@layout.add_widget(Qt::Label.new('',nil),20,0)
	end
end

class ConfigUI < Qt::Widget
	def initialize(inputs, parent=nil)
		super(parent)
		@inputs = inputs

		@layout = Qt::GridLayout.new(self)

		@layout.add_widget(Qt::Label.new('Class Entry',nil),0,0)
		@layout.add_widget(@inputs['Class Entry'],0,1)
		@layout.add_widget(Qt::Label.new('Race Entry',nil),1,0)
		@layout.add_widget(@inputs['Race Entry'],1,1)
		@layout.add_widget(Qt::Label.new('Skill Entry',nil),2,0)
		@layout.add_widget(@inputs['Skill Entry'],2,1)
		
		#Spacer
		@layout.add_widget(Qt::Label.new('',nil),20,2)
	end
end

class BrowseButton < Qt::PushButton
	# File browse button
	# Modify the selected lineedit when you find a file
	def initialize(line_edit,directory=false,default_path=nil,parent=nil)
		super("Browse...",parent)

		self.connect(SIGNAL(:clicked)) {
			self.browse_for_file(line_edit,directory,default_path)
		}
	end
	def browse_for_file(line_edit,directory,default_path)
		file = ''
		Qt::FileDialog.new do |fd|
			if directory
				result = fd.get_existing_directory(nil,'Browse for Folder',line_edit.text)
			else
				start_path = File.dirname(line_edit.text)
				$log.info "Start Path: #{start_path.inspect}"
				if start_path == '.' and not default_path.nil?
					start_path = default_path.text
					$log.info "Start Path: #{start_path.inspect}"
				end

				result = fd.get_open_file_name(nil,'Browse for File',start_path)
			end
			# Send the result to the line edit; process it if need be.
			if result
				result.gsub! '\\', '/'
				line_edit.text = result
				# Include only the filename if the path is the same as the default
				if not (directory or default_path.nil?) and (default_path.text.gsub('\\','/') == File.dirname(result))
					line_edit.text = File.basename(result)
				end
			end
		end
	end
end
