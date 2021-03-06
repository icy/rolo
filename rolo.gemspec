#!/usr/bin/env ruby

# Purpose: Gem specification
# Author : Anh K. Huynh
# License: GPL-2.0
# Date   : 2012 July 20th

Gem::Specification.new do |s|
  s.license = 'GPL-2.0'
  s.name = 'rolo'
  s.version = '1.1.6'
  s.date = '2017-08-27'
  s.summary = "`rolo` prevents a program from running more than one copy at a time"
  s.description = "Start an application and/or prevent it from running twice by simply checking if there is a network socket that is open by the application and/or by `rolo`"
  s.authors = ["Anh K. Huynh"]
  s.email = 'kyanh@viettug.org'
  s.files = %w(README.md)
  s.homepage = 'https://github.com/icy/rolo'
  s.executables << "rolo"
end
