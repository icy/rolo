## NAME

  `rolo.rb` -- Prevents a program from running more than one copy at a time

## SYNOPSIS

<pre>
  $0 [-v] [--test] [-a address] -p port_number command [arguments]
</pre>

## DESCRIPTION

  `rolo.rb` prevents a program from running more than one copy at a time;
   it is useful with cron to make sure that a job doesn't run before a
   previous one has finished. `robo.rb` is a ruby version of Timothy
   program `solo` with more options.

## OPTIONS

  * `-v` (`--verbose`)  print verbose message
  * `-t` (`--test`)     test of program is running. Don't execute any command.
  * `-a` (`--address`)  address to check / listen on
  * `-p` (`--port`)     port to check / on which rolo will listen

In `<command>` and `<arguments>`, you can use `%address`, `%port` which
are replaced by the socket address and port that the problem uses to
check for status of your command. This is very useful if your command
closes all file descriptors at the time it runs, but it has some ways
to listen on `%address:%port`. See EXAMPLE for details.

## HOW IT WORKS

  Before starting your `<command>` (using `exec`), `rolo.rb` will open a
  socket on a local address `127.x.y.1:<port>` (`x.y` is translated
  from process's user id hence that allows two different users on the
  system to use the same `<port>`; You can specify address by using the
  option `--address <address>`, though.) This socket will be closed
  after your command exits. And as long as your command is running, we
  have a chance to check its status by simply checking the status of
  this socket. If it is still open when `rolo.rb` is invoked, `rolo.rb`
  will exit without invoking a new instance of your program.

  However, if your `<command>` closes all file descriptors at the time it
  is executed, `rolo.rb` will be sucked. See `EXAMPLE` for details and for
  a trick when using `rolo.rb` with `ssh`.

## EXAMPLE

  To create tunnel to a remote server, you can use this ssh command

<pre>
ssh -fN remote -L localhost:1234:localhost:10000
</pre>

  This allows you to connect to the local port 1234 on your mahince
  as same as conneting to address `localhost:10000` on remote server.
  The process `ssh` will go to background immediately after it authenticates
  successfully with the remote.

  To keep this tunnel persistent, you can add this to your crontab

<pre>
rolo.rb -p 4567 ssh -fN remote -L localhost:1234:localhost:10000
</pre>

  and allows this line to be executed once every 5 minutes. `rolo.rb`
  will check if your ssh command is still running. If 'yes', it will
  simply exit; if 'no', `rolo.rb` will start the ssh command.

  However, if you use *OpenSSH 5.6p1* (or later), `ssh` will close all file
  descriptors from the parent (except for `STDIN`, `STDOUT` and `STDERR`).
  As the socket opened by `rolo.rb` is closed, `rolo.rb` will always
  start new instance of the `ssh` tunnel. (Actually I had process `bomb`
  on my system when I used the original program `solo` to launch my
  tunnels.)

  Fortunately, `ssh` has option to bind on the local address.
  Using this option we can trick `rolo.rb` as below
<pre>
rolo.rb -p 4567 \
    ssh -fN remote \
      -L localhost:1234:localhost:10000 \
      -L %address:%port:localhost:10000
</pre>

  The last use of option `-L` will ask `ssh` to open a socket on
  `%address:%port` (the real values will be provided by `rolo.rb`),
  and it will be checked by `rolo.rb` in its next run.

  Another way is to use option `--address`

<pre>
rolo.rb -p 4567 -a 127.0.0.1 \
    ssh -fN remote \
      -L localhost:1234:localhost:10000
</pre>

