#!/usr/bin/env ruby

class NERO_Config
	def initialize filename
		begin
			File.open(filename,'r') do |cfile|
				@config = YAML.load(cfile)
			end
			@filename = filename
			@config_dir = File.expand_path(File.dirname(filename))
		rescue
			@config = {}
			$log.error "Could not open configuration file ('#{filename}')"
		end
		@default_config = {}
		@default_config['Enable Logging'] = true
		@default_config['Log Output'] = 'nero.log'
		@default_config['Log Count'] = 1
		@default_config['Log Size'] = 1024
		@default_config['Log Threshold'] = 'Warnings'
		@default_config['Skill Count Min Width'] = 10
		@default_config['Skill Count Max Width'] = 20
		@default_config['Skill Count Min Height'] = 10
		@default_config['Skill Count Max Height'] = 20
		@default_config['Skill Entry'] = 'Drop Down' # Other choice: Line Edit
		@default_config['Title'] = 'NERO Character Creator'
		@default_config['Main Module'] = 'ncc_data.yml'
		@default_config['Working Directory'] = Dir.pwd()
		@default_config['Goblins'] = 'Individual'
		@default_config['Enable Autosave'] = true
		@default_config['Autosave'] = 'ncc.yml'
		@default_config['Export'] = "#{ENV['USERPROFILE'].gsub('\\','/')}/Desktop"
		@default_config['Race Entry'] = 'Drop Down'
		@default_config['Class Entry'] = 'Drop Down'
		@default_config['Editor'] = "notepad.exe"
		@default_config['Satisfy Prerequisites'] = true

		@default_config['Enforce Build'] = false

		@last_setting = ''
	end

	def setting name = @last_setting
		name = name.to_s
		@last_setting = name

		return @config[name] if @config.has_key?(name)
		return @default_config[name] if @default_config.has_key?(name)
		return nil
	end

	def update_setting(key,val)
		@config[key] = val
		# Avoid storing default configuration in config files
		@config.delete key if @default_config[key] == val
	end

	def chdir
		$log.debug 'NERO_Config.chdir()'
		begin
			$log.debug "NERO_Config.chdir() - 'Save Directory' == #{self.setting('Save Directory')}"
			if self.setting('Save Directory').to_s.upcase != 'PROGRAM'
				if self.setting('Save Directory').nil?
					Dir.chdir(ENV['USERPROFILE'])
					if RUBY_PLATFORM.include?('win32') or RUBY_PLATFORM.include?('i386-mingw32')
						$log.debug "Platform is Windows, changing to Personal directory"
						Dir.chdir(Dir::PERSONAL)
					end
				else
					Dir.chdir($config.setting)
					$log.debug "NERO_Config.chdir() - 'Save Directory' variable set, changed directory to #{$config.setting}"
				end
			end
		rescue
			$log.error "NERO_Config.chdir() - Failed to set documents directory..."
		end
	end

	def commit_settings
		$log.info "Config::commit_settings()"
		retval = true
		cwd = Dir.getwd()
		Dir.chdir(@config_dir)

		begin
			File.open(@filename,'w') do |f|
				f.write(YAML.dump(@config))
			end
		rescue Exception => e
			$log.error "Could not save configuration file..."
			$log.error e.inspect
			$log.error e.backtrace
			retval = false
		end
		Dir.chdir(cwd)

		return retval
	end

end

if __FILE__ == $0
	require 'log.rb'
	$log = Logger.new('config.log',10,102400)
	$log.info "Testing config.rb"
	$log.warn "Nothing to test"
end

