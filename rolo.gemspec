#!/usr/bin/env ruby

# Purpose: Gem specification
# Author : Anh K. Huynh
# License: GPL2
# Date   : 2012 July 20th

Gem::Specification.new do |s|
  s.license = 'GPL v2'
  s.name = 'rolo'
  s.version = '1.1.2'
  s.date = '2013-07-22'
  s.summary = "`rolo` prevents a program from running more than one copy at a time"
  s.description = "Start an application and/or prevent it from running twice by simply checking if there is a network socket that is open by the application and/or by `rolo`"
  s.authors = ["Anh K. Huynh"]
  s.email = 'kyanh@viettug.org'
  s.files = %w(README.md)
  s.homepage = 'https://github.com/icy/rolo'
  s.executables << "rolo"
end
