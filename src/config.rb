#!/usr/bin/env ruby

require 'rubygems'
require 'win32/dir' if RUBY_PLATFORM.include?('win32') or RUBY_PLATFORM.include?('i386-mingw32')

class NERO_Config
	def initialize filename
		begin
			@config = YAML.load(File.open(filename,'r'))
		rescue
			@config = {}
			$log.error "Could not open configuration file ('#{filename}')"
		end
		@default_config = {}
		@default_config['Log Output'] = Dir.pwd + '/nero.log'
		@default_config['Log Count'] = 5
		@default_config['Log Size'] = 102400
		@default_config['Skill Count Min Width'] = 10
		@default_config['Skill Count Max Width'] = 20
		@default_config['Skill Count Min Height'] = 10
		@default_config['Skill Count Max Height'] = 20
		@default_config['Skill Entry'] = 'Drop Down' # Other choice: Line Edit
		@default_config['Title'] = 'NERO Character Creator'
		@default_config['Skill Data'] = 'skills.yml'
		@default_config['Working Directory'] = Dir.pwd()
		@default_config['Goblins'] = 'Individual'
		@default_config['Autosave'] = 'ncc.yml'
		@default_config['Export'] = "#{ENV['USERPROFILE']}/Desktop"
		@default_config['Race Entry'] = 'Drop Down'
		@default_config['Class Entry'] = 'Drop Down'

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
	end

	def chdir
		$log.debug 'Changing default directory...'
		begin
			if self.setting('Save Directory').upcase != 'PROGRAM'
				Dir.chdir(ENV['USERPROFILE'])
				if RUBY_PLATFORM.include?('win32') or RUBY_PLATFORM.include?('i386-mingw32')
					$log.debug "Platform is Windows, changing directory to #{Dir::PERSONAL}"
					Dir.chdir(Dir::PERSONAL)
				end
				unless self.setting('Save Directory').nil?
					Dir.chdir($config.setting)
					$log.debug "'Save Directory' variable set, changing directory to #{$config.setting}"
				end
			end
		rescue
			$log.error "Failed to set documents directory..."
		end
	end

end

if __FILE__ == $0
	require 'log.rb'
	$log = Logger.new('config.log',10,102400)
	$log.info "Testing config.rb"
	$log.warn "Nothing to test"
end

