#!/usr/bin/env ruby

require 'logger'

=begin
FATAL:	an unhandleable error  that results in a program crash
ERROR:	a handleable error condition
WARN:	a warning
INFO:	generic (useful) information about system operation
DEBUG:	low-level information for developers 
=end
class TempLog
	attr_reader :msg
	def initialize
		@msg = []
	end
	def debug m
		@msg << [:D,m]
	end
	def info m
		@msg << [:I,m]
	end
	def warn m
		@msg << [:W,m]
	end
	def error m
		@msg << [:E,m]
	end
	def fatal m
		@msg << [:F,m]
	end

	def TempLog.export data
		data.each do |m|
			case m[0]
			when :D then
				$log.debug m[1]
			when :I then
				$log.info m[1]
			when :W then
				$log.warn m[1]
			when :E then
				$log.error m[1]
			when :F then
				$log.fatal m[1]
			end
		end
	end
end

class FallbackLog
	attr_reader :msg
	def initialize
		@msg = []
	end
	def debug m
	end
	def info m
	end
	def warn m
	end
	def error m
	end
	def fatal m
	end
end



$log = TempLog.new()

def init_log
	temp_data = $log.msg
	if $config.setting('Log Output').upcase == "STDOUT"
		$log = Logger.new(STDOUT)
	else
		begin
			# Creates a logger based off of configuration settings
			$log = Logger.new($config.setting('Log Output'), $config.setting('Log Count'), $config.setting('Log Size'))
		rescue
			$log = FallbackLog.new()
		end
	end

	TempLog.export(temp_data)
	
	$log.sev_threshold = Logger::INFO
	unless $config.setting("Log Threshold").nil?
		case $config.setting.upcase
		when 'DEBUG' then
			$log.sev_threshold = Logger::DEBUG
		when 'INFO' then
			$log.sev_threshold = Logger::INFO
		when 'WARN' then
			$log.sev_threshold = Logger::WARN
		when 'ERROR' then
			$log.sev_threshold = Logger::ERROR
		when 'FATAL' then
			$log.sev_threshold = Logger::FATAL
		end
	end
end

if __FILE__ == $0
	$log = Logger.new('log.log',10,102400)
	$log.info "Testing log.rb"
	$log.warn "Nothing to test"
end

