#!/usr/bin/env ruby

# Purpose: Gem specification
# Author : Anh K. Huynh
# License: GPL2
# Date   : 2012 July 20th

Gem::Specification.new do |s|
  s.name = 'rolo'
  s.version = '1.0.2'
  s.date = '2012-07-20'
  s.summary = "`rolo` prevents a program from running more than one copy at a time"
  s.description = "Prevents a program from running more than one copy at a time"
  s.authors = ["Anh K. Huynh"]
  s.email = 'kyanh@viettug.org'
  s.files = %w(README.md)
  s.homepage = 'https://github.com/icy/rolo'
  s.executables << "rolo"
end
