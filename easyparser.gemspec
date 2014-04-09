Gem::Specification.new do |s|
  s.name        = 'easyparser'
  s.version     = '0.0.3'
  s.date        = '2014-04-03'
  s.summary     = 'EasyParser: A scraper engine for everyone'
  s.description = 'EasyParser is a web scraper engine that allows for writing scrapers in the same language web pages are written, accelerating the creation process, maintainance and error correction.'
  s.authors     = ['Gustavo Armagno']
  s.email       = 'gustavoa@gmail.com'
  s.files       = ['lib/easyparser.rb']
  s.homepage    = 'https://github.com/gusaaaaa/easyparser'
  s.license     = 'MIT'

  s.add_dependency 'nokogiri', '~> 1.6.1'
end
