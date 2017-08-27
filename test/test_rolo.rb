#!/usr/bin/env ruby

require 'rake/testtask'
require 'test/unit'

class RoloTest < Test::Unit::TestCase
  @@rolo = File.join(File.dirname(__FILE__), "../bin/rolo")
  @@port = ENV['ROLO_TEST_PORT'] || (rand(65000 - 1024) + 1024)
  @@addr = ENV['ROLO_TEST_ADDR'] || '127.0.0.1'

  def test_low_port
    ret = %x{#{@@rolo} --port 123 sleep 100 2>&1}
    assert_match /Permission denied/, ret
  end

  def test_no_command
    ret = %x{#{@@rolo} --port #{@@port} 2>&1}
    assert_match /You must provide a command/, ret
  end

  def test_running
    num_secs = 3

    test_cmd = "#{@@rolo} --address #{@@addr} --port #{@@port} sleep #{num_secs}"

    (pid = Process.fork) ? Process.detach(pid) : exec(test_cmd)

    ret = %x[#{test_cmd} 2>&1]
    assert_match /your application running/, ret

    begin
      STDERR.puts ":: Wait #{num_secs} seconds for cleaning up..."
      Process.wait(pid)
    rescue
      nil
    end
  end
end
