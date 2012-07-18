#!/usr/bin/env ruby
#
# Purpose: Prevents a program from running more than one copy at a time
#          This is a ruby version of Timothy program solo with more options
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
#          [8] OpenSSH   : http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-5.9p1.tar.gz
#          [9] closefrom : http://www.unix.com/man-page/All/3c/closefrom/
#
# SYNTAX
#
#   $0 [--verbose] [--test] [--port <port_number>] <command> [<arguments>]
#
# OPTIONS
#
#   -v (--verbose)  print verbose message
#   -t (--test)     test of program is running. Don't execute any command.
#   -p (--port)     specify the port on which the rolo listens
#
#   In <command> and <arguments>, you can use '%address', '%port' which
#   are replaced by the socket address and port that the problem uses to
#   check for status of the program. This is very useful if your program
#   closes all file descriptors at the time it runs, but it has some ways
#   to listen on '%address:%port'. See Example for details.
#
# HOW IT WORKS
#
#   Before starting your <command> (using (exec)), `rolo.rb` will open a
#   socket on a local address `127.x.y.1:<port>` (`x.y` is translated
#   from process's user id hence that allows two different users on the
#   system use the same <port>.)  This socket will immediately closed
#   after your program exit. And as long as your program is running, we
#   have a chance to check its status by simply checking the status of
#   this socket. If it is still open when 'rolo.rb' is invoked, 'rolo.rb'
#   will exit without invoking a new instance of your program.
#
#   However, if you <command> closes all file descriptors at the time it
#   is executed, `rolo.rb` will be sucked. See EXAMPLE for details and for
#   a trick when using `rolo.rb` with `ssh`.
#
# EXAMPLE
#
#   To create tunnel to a remote server, you can use this ssh command
#       ssh -fN remote -L localhost:1234:localhost:10000
#   This allows you to connect to the local port 1234 on your mahince
#   as same as conneting to address 'localhost:10000' on remote server.
#
#   To keep this tunnel persistent, you can add this to your crontab
#       rolo.rb -p 4567 ssh -fN remote -L localhost:1234:localhost:10000
#   and allows this line to be executed once every 5 minutes. `rolo.rb`
#   will check if your ssh command is still running. If 'yes', it will
#   simply exit; if 'no', `rolo.rb` will start the ssh command.
#
#   However, if you are using OpenSSH 5.9p1, `ssh` will close all file
#   descriptors from the parent (except for STDIN, STDOUT and STDERR).
#   As the socket opened by `rolo.rb` is closed, `rolo.rb` will always
#   start new instance of the `ssh` tunnel. Fortunately, `ssh` has option
#   to bind on local address, and here is the trick
#       rolo.rb -p 4567 \
#           ssh -fN remote \
#             -L localhost:1234:localhost:10000 \
#             -L %address:%port:localhost:10000
#   The last use of the option `-L` will ask `ssh` to open a socket on
#   `%address:%port` (the real values will be provided by `rolo.rb`), and
#   it will be checked by `rolo.rb` in its next run.
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
#
# Note [8]:
#   In the source code of OpenSSH 5.9p1, ssh.c::268 we can see that all
#   file descriptors from (STDERR_FILENO + 1) will be closed by the
#   function (closefrom) (see [9].) This may cause problem!
#
#   /*
#   * Discard other fds that are hanging around. These can cause problem
#   * with backgrounded ssh processes started by ControlPersist.
#   */
#   closefrom(STDERR_FILENO + 1);
#
#   On my system (ArchLinux, 3.3.8), (closefrom) is not found. The method
#   should be used from (openbsd-compact/bsd-closefrom.c).s
#
#   This behavior is implemented since OpenSSH 5.6p1.
#

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
  elsif %w{-t --test}.include?(f)
    OPTIONS[:test] = true
    ARGV.shift
  elsif %w{--}.include?(f)
    ARGV.shift
    break
  else
    break
  end
end

"Port must be a positive number".die if OPTIONS[:port] == 0

cmd = ARGV.shift.to_s
"You must provide a command".die if cmd.empty?
cmd = "#{cmd} #{ARGV.join(' ')}" unless ARGV.empty?

address = [127, Process.uid, 1].pack("CnC").unpack("C4").join(".")

cmd = cmd.gsub("%port", OPTIONS[:port].to_s).gsub("%address", address)

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

unless OPTIONS[:test]
  close_on_exec(false)
  exec cmd
end
