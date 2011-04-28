#!/usr/bin/env ruby

# This file is used to test other NCC files in IRB

def init_ncc()
	require 'character.rb'
	require 'build.rb'
	require 'character_skill.rb'
	require 'nero_skills.rb'
	require 'config.rb'
	require 'log.rb'
	
	require 'rubygems'
	require 'Qt4'
	
	require 'date'


	$data_path = "#{Dir.getwd()}/"
	$config = NERO_Config.new($data_path + 'ncc.ini')
	$config.update_setting('Log Threshold','DEBUG')
	$config.update_setting('Log Output','STDOUT')
	init_log()
	$config.chdir()
	NERO_Data.initialize_statics 'ncc.yml'
	$character = NERO_Character.new()
end

def start_app
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



