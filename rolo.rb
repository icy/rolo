#!/usr/bin/env ruby
#
# Purpose: A ruby version of Timothy program solo
# Author : Anh K. Huynh
# License: GPL2
# Date   : 2012 July 16th
# Link   : [1] Tim's solo: http://github.com/timkay/solo/
#          [2] Fork-exec : http://en.wikipedia.org/wiki/Fork-exec
#          [3] Unix fork : http://www-h.eng.cam.ac.uk/help/tpl/unix/fork.html
#          [4] Fork-exec : http://jacktang.github.com/2009/01/04/ruby-fork-exec-socket-hang.html
#          [5] ^F in Perl: http://perldoc.perl.org/perlvar.html#%24^F
#          [6] RubyPaint : http://ruby.runpaint.org/io
#          [7] Secure FD : http://udrepper.livejournal.com/20407.html
#
# Syntax : $0 [--verbose] [--port <port_number>] <command> [<arguments>]
#
# Note [5]:
#   The maximum system file descriptor, ordinarily 2. System file descrip-
#   tors are passed to exec()ed processes, while higher file descriptors
#   are not. Also, during an open(), system file descriptors are preserved
#   even if the open() fails (ordinary file descriptors are closed before
#   the open() is attempted). The close-on-exec status of a file descrip-
#   tor will be decided according to the value of $^F when the correspon-
#   ding file, pipe, or socket was opened, not the time of the exec().
#
# Note [6]:
#   On a Unix-based system a process created by Kernel.exec, Kernel.fork,
#   or IO.popen inherits the file descriptors of its parent. Depending on
#   the application, this may constitute an information leak in that the
#   child is able to access data that he shouldn’t have access to. If
#   given a true argument, IO#close_on_exec= ensures that its receiver
#   is closed before the new process is created; otherwise, it does not.
#   IO#close_on_exec? returns the status of this flag as either true or
#   false. On systems that don’t support this feature, these methods
#   raise NotImplementedError.

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

# Based on the original code taken from from [4]
def close_on_exec(att = true)
  ObjectSpace.each_object(IO) do |io|
    begin
      if io.respond_to?(:close_on_exec?)
        io.close_on_exec = attr
      else
        io.fcntl(Fcntl::F_SETFD, attr ? Fcntl::FD_CLOEXEC : 0)
      end
    rescue ::Exception => err
    end unless [STDIN, STDOUT, STDERR].include?(io) or io.closed?
  end
end

OPTIONS = {:verbose => false, :port => 0}

"Syntax: rolo [--verbose] --port <port_number> <command> [<arguments>]".die if ARGV.empty?

while true
  f = ARGV.first
  if %w{-p --port}.include?(f)
    ARGV.shift
    OPTIONS[:port] = ARGV.shift.to_s.to_i
    "Port must be a positive number".die if OPTIONS[:port] == 0
  elsif %w{-v --verbose}.include?(f)
    OPTIONS[:verbose] = true
    ARGV.shift
  else
    break
  end
end

"Port must be a positive number".die if OPTIONS[:port] == 0

cmd = ARGV.shift.to_s
"You must provide a command".die if cmd.empty?
cmd = "#{cmd} #{ARGV.join(' ')}" unless ARGV.empty?

address = [127, Process.uid, 1].pack("CnC").unpack("C4").join(".")
("Will bind on %s:%d, command = '%s'" \
  % [address, OPTIONS[:port], cmd]).verbose(OPTIONS[:verbose])

# Taken from example in the source code documetation
# Link: http://ruby-doc.org/stdlib-1.8.7/
#         libdoc/socket/rdoc/Socket.html#method-i-bind
begin
  include Socket::Constants
  socket = Socket.new(AF_INET, SOCK_STREAM, 0)
  socket.bind(Socket.pack_sockaddr_in(OPTIONS[:port], address))
rescue Errno::EADDRINUSE
  "Address is in use. Is your application running?".die(0, STDOUT)
rescue => e
  e.to_s.die(1)
end

close_on_exec(false)
exec cmd
