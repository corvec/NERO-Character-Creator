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

class NERO_Player
	attr_reader :player_name
	attr_reader :address
	attr_reader :phone
	attr_reader :birth_date
	attr_reader :membership
	attr_reader :legal_release
	attr_reader :goblins
	attr_reader :notes
	attr_reader :characters
	
	def initialize(player_name = {:first=>'',:last=>''}, address = {:address=>'',:state=>'',:zip=>'',:city=>''} phone = '', birth_date = nil, membership = nil, legal_release = nil, goblins = 0)
		@player_name   = player_name
		@address       = address
		@phone         = phone
		@birth_date    = birth_date
		@membership    = membership
		@legal_release = legal_release
		@goblins       = goblins

		@notes         = []
		@characters    = []
	end

	def character+= character
		@characters << character
	end

	def add_note note
		@notes << note
	end

	def get_name
		"#{@name[:last]}, #{@name[:first]}"
	end

	def goblins=(goblins)
		@goblins = goblins.to_i
	end

	def goblins-=(expenditure)
		@goblins -= expenditure.to_i
	end

	def goblins+=(reward)
		@goblins += reward.to_i
	end

	# Parameters: date - date purchased
	def purchase_membership date = nil
		# Default to today
		if date == nil
			date = Date.today
		end
		# Parse Strings
		if !date.instance_of?(Date) and date.instance_of?(String)
			d = ParseDate.parsedate(date,true)
			d_comp = [Date.today.year, Date.today.month, Date.today.mday]
			(0..2).each do |i|
				d[i] = d_comp[i] if d[i] == nil
			end
			d[0] += 100 while d[0] < Date.today.year
			date = Date.new(d[0],d[1],d[2])
		end

		@membership = Date.new(date.year+1,date.month,date.mday)
	end
end

p = NERO_Player.new(name="Corvec")

