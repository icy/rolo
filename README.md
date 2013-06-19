## NAME

  `rolo.rb` -- Prevents a program from running more than one copy at a time

## SYNOPSIS

    $0 [options] command [arguments]

## DESCRIPTION

  Start an application and/or prevent it from running twice by simply
  checking if there is a network socket that is open by the application
  and/or by `rolo`.

  `rolo.rb` prevents a program from running more than one copy at a time;
  it is useful with cron to make sure that a job doesn't run before a
  previous one has finished. `robo.rb` is a ruby version of Timothy
  program <https://github.com/timkay/solo> with some more options.

## OPTIONS

  Please run the command `rolo` without any arguments for more details.

## INSTALLATION

  This program can be installed by using RubyGems

    gem install --remote rolo

  You can build and install it locally

    git clone git://github.com/icy/rolo.git
    cd rolo
    gem build rolo.gemspec
    gem install --local rolo-VERSION.gem

## HOW IT WORKS

  If the `--no-bind` option is used, the program will simply assume that
  the port is open by another program and it will only check if that port
  is open or not. Otherwise, see below.

  Before starting your `<command>` (using `exec`), `rolo.rb` will open a
  socket on a local address (or address specified by option `--address`.)
  This socket will be closed after your command exits, and as long as
  your command is running, we have a chance to check its status by
  checking the status of this socket. If it is still open when `rolo.rb`
  is invoked, `rolo.rb` exits without invoking a new instance of command.

  However, if your `<command>` closes all file descriptors at the time it
  is executed, `rolo.rb` will be sucked. (See `EXAMPLE` for details and for
  a trick when using `rolo.rb` with `ssh`.) If that the cases, you may
  use the option `--address` and `--port` to specify a socket that your
  command binds on.

## EXAMPLE

  Here are some simple examples and applications. Feel free to contribute.

### Create SSH tunnels

  To create tunnel to a remote server, you can use this ssh command

    ssh -fN remote -L localhost:1234:localhost:10000

  This allows you to connect to the local port 1234 on your mahince
  as same as conneting to address `localhost:10000` on remote server.
  The process `ssh` will go to background immediately after it authenticates
  successfully with the remote.

  To keep this tunnel persistent, you can add this to your crontab

    rolo.rb -p 4567 \
      ssh remote -fNL localhost:1234:localhost:10000

  and allows this line to be executed once every 5 minutes. `rolo.rb`
  will check if your ssh command is still running. If 'yes', it will
  simply exit; if 'no', `rolo.rb` will start the ssh command.

### With OpenSSH 5.6p1 or later

  However, if you use *OpenSSH 5.6p1* (or later), `ssh` will close all file
  descriptors from the parent (except for `STDIN`, `STDOUT` and `STDERR`).
  As the socket opened by `rolo.rb` is closed, `rolo.rb` will always
  start new instance of the `ssh` tunnel. (Actually I had process `bomb`
  on my system when I used the original program `solo` to launch my
  tunnels.)

  Fortunately, `ssh` has option to bind on the local address.
  Using this option we can trick `rolo.rb` as below

    rolo.rb -p 4567 \
      ssh remote -fN \
        -L localhost:1234:localhost:10000 \
        -L %address:%port:localhost:12345

  The last use of option `-L` will ask `ssh` to open a socket on
  `%address:%port` (the real values will be provided by `rolo.rb`),
  and it will be checked by `rolo.rb` in its next run. Please note that
  we use a random port `12345` to prevent local connections to
  `%address:%port` from being forwarded to remote.

  Another way is to use option `--address`

    rolo.rb -p 1234 -a 127.0.0.1 \
      ssh remote -fNL localhost:1234:localhost:10000

  And this is another way

    rolo.rb -p 1234 -a 127.0.0.1 \
      ssh remote -fNL %address:%port:localhost:10000

### Start VirtualBox guests

  To make sure that your VirtualBox Windows guest is always running,
  you can use:

    rolo -a 1.2.3.4 -p 3389 --no-bind \
      VBoxManage startvm foobar --type headless

  Here `1.2.3.4` is the guest's address, and `3389` is the port
  that is used by `rdesktop` service on the guest.
