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

# A NERO Class should have the following properties:
# * name
# * base body
# * body per level
class NERO_Class
	@@class_list = []
	@@class_data = {}
	def NERO_Class::add_classes(class_data)
		class_data.each do |class_name, data|
			@@class_list << class_name
			@@class_data[class_name] = {}
			@@class_data[class_name]['Base Body'] = class_data[class_name]['Base Body'].to_f
			@@class_data[class_name]['Body Per Level'] = class_data[class_name]['Body Per Level'].to_f
		end
		@@class_list.sort!
	end


	def initialize(character_class = nil)
		@character_class = @@class_list.first if @character_class.nil?
		@character_class = (@@class_list.include? character_class) ? character_class : @@class_list[0]
	end

	def NERO_Class::list
		@@class_list.clone
	end

	def name
		return @character_class
	end

	def body level
		@@class_data[@character_class]['Base Body'] + level * @@class_data[@character_class]['Body Per Level']
	end

	def to_s
		return @character_class
	end
end


if __FILE__ == $0
	$log = Logger.new('nero_class.log',10,102400)
	$log.info "Testing nero_class.rb"
	$log.warn "Nothing to test"
end
