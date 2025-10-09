# encoding: UTF-8
require File.expand_path('../lib/mark_mapper/version', __FILE__)

Gem::Specification.new do |s|
  s.name               = 'mark_mapper'
  s.homepage           = 'http://paxtonhare.github.io/markmapper/'
  s.summary            = 'A Ruby Object Mapper for MarkLogic'
  s.description        = 'MarkMapper is a Object-Document Mapper for Ruby and Rails'
  s.require_path       = 'lib'
  s.license            = 'MIT'
  s.authors            = ['Paxton Hare']
  s.email              = ['paxton@greenllama.com']
  s.executables        = []
  s.version            = MarkMapper::Version
  s.platform           = Gem::Platform::RUBY
  s.files              = Dir.glob("{bin,examples,lib,spec}/**/*") + %w[LICENSE README.rdoc]

  s.required_ruby_version = '>= 3.2'
  s.add_runtime_dependency 'activemodel', '>= 8.0'
  s.add_runtime_dependency 'activesupport', '>= 8.0'
  s.add_runtime_dependency 'marklogic-mock', '~> 0.1'
end
