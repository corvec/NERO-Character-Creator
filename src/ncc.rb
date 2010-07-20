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

require 'character.rb'
require 'build.rb'
require 'character_skill.rb'
require 'nero_skills.rb'
require 'config.rb'
require 'log.rb'
require 'gui.rb'


# Run the application
if __FILE__ == $0
	$log.info "Starting NERO Character Creator (by Corvec!)..."

	$data_path = "#{Dir.getwd()}/"
	$config = NERO_Config.new($data_path + 'ncc.ini')

	init_log()

	$config.chdir()

	$nero_skills = NERO_Skills.new($data_path + 'skills.yml')
	$character = NERO_Character.new()
	if not defined?(Ocra)
		app = Qt::Application.new(ARGV)
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
