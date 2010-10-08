#!/usr/bin/env ruby

=begin
	This file is part of the NERO Character Creator.

	NERO Character Creator is free software: you can redistribute it
	and/or modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation, either version 3 of
	the License, or (at your option) any later version.

	NERO Character Creator is distributed in the hope that it will
	be useful, but WITHOUT ANY WARRANTY; without even the implied
	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with the NERO Character Creator.
	If not, see <http://www.gnu.org/licenses/>.
=end

require 'rubygems'
require 'Qt4'
require 'date'
require 'optparse'
require 'win32/dir' if RUBY_PLATFORM.include?('win32') or RUBY_PLATFORM.include?('i386-mingw32')

if Dir.pwd() != File.expand_path(File.dirname(__FILE__))
	$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
end

require 'character.rb'
require 'build.rb'
require 'character_skill.rb'
require 'nero_data.rb'
require 'config.rb'
require 'log.rb'
require 'gui.rb'


# Run the application
if __FILE__ == $0
	$log.info "Starting NERO Character Creator (by Corvec!)..."


	ARGV.each do |arg|
		if File.exists?(arg)
			$config = NERO_Config.new(arg) if $config.nil?
			break
		end
	end

	$config = NERO_Config.new('ncc.ini') if $config.nil?

	init_log()

	NERO_Data.initialize_statics($config.setting('Main Module'))

	$character = NERO_Character.new()
	if not defined?(Ocra)
		app = Qt::Application.new(ARGV)

		unless NERO_Data.initialized?
			err = Qt::MessageBox.new(nil,"Error loading...","Failed to load main data module, #{$config.setting('Main Module')}")
			err.show
			exit
		end

		my_widget = BaseWidget.new()
		my_widget.show()
		begin
			app.exec
		rescue Exception => e
			$log.fatal e.inspect
			$log.fatal e.backtrace
		end
	end
end
