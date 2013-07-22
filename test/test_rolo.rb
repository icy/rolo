#!/usr/bin/env ruby

require 'rake/testtask'
require 'test/unit'

class RoloTest < Test::Unit::TestCase
  @@rolo = File.join(File.dirname(__FILE__), "../bin/rolo")
  @@port = ENV['ROLO_TEST_PORT'] || '10002'
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
    (pid = fork) ? Process.detach(pid) : exec("#{@@rolo} --address #{@@addr} --port #{@@port} sleep 3 2>&1")
    ret = %x{#{@@rolo} --port #{@@port} --address #{@@addr} sleep 2 2>&1}
    assert_match /your application running/, ret
    begin Process.wait(pid) rescue nil ; end
    sleep(3)
  end
end
