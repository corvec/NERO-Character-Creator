#!/usr/bin/env ruby

require 'logger'

=begin
FATAL:	an unhandleable error  that results in a program crash
ERROR:	a handleable error condition
WARN:	a warning
INFO:	generic (useful) information about system operation
DEBUG:	low-level information for developers 
=end

# Remove this line for production
#$log = Logger.new(STDOUT) unless defined? $log

# Creates a logger that ages files once they reach 100KB and stores up to 20
$log = Logger.new(Dir.pwd + '/nero.log', 20, 102400) unless defined? $log

$log.sev_threshold = Logger::INFO

if __FILE__ == $0
	$log = Logger.new('log.log',10,102400)
	$log.info "Testing log.rb"
	$log.warn "Nothing to test"
end

