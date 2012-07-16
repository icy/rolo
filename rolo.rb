#!/usr/bin/env ruby

# Purpose: A ruby version of Timothy program solo
# Author : Anh K. Huynh
# License: GPL2
# Date   : 2012 July 16th
# Link   : https://github.com/timkay/solo/

# Syntax : $0 [--verbose] [--port <port_number>] <command> [<arguments>]

require 'socket'

class String
  def die(ret = 1, dev = STDERR)
    dev.puts(":: #{self}")
    exit(ret)
  end

  def verbose(v = false)
    STDERR.puts(":: #{self}") if v
  end
end

args = Array(ARGV)
OPTIONS = {:verbose => false, :port => 0}

"Syntax: rolo [--verbose] --port <port_number> <command> [<arguments>]".die if args.empty?

while true
  f = args.first
  if %w{-p --port}.include?(f)
    args.shift
    OPTIONS[:port] = args.shift.to_s.to_i
    "Port must be a positive number".die if OPTIONS[:port] == 0
  elsif %w{-v --verbose}.include?(f)
    OPTIONS[:verbose] = true
    args.shift
  else
    break
  end
end

"Port must be a positive number".die if OPTIONS[:port] == 0

cmd = args.shift.to_s
"You must provide a command".die if cmd.empty?
address = [127, Process.uid, 1].pack("CnC").unpack("C4").join(".")

begin
  socket = Socket.new(:INET, :STREAM, 0)
  socket.bind(Addrinfo.tcp(address, OPTIONS[:port]))
rescue Errno::EADDRINUSE
  "Address is in use. Is your application running?".die(1, STDOUT)
rescue => e
  e.to_s.die(1)
end

("Binded on %s, command = '%s', args = '%s'" \
  % ["#{address}:#{OPTIONS[:port]}", cmd, args.join(' ')]).verbose(OPTIONS[:verbose])

exec cmd, args.join(" ")
