require 'mindi'

Gem::Specification.new do |s|
  s.name = "mindi"
  s.version = MinDI::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0")
  s.authors = ["Joel VanderWerf"]
  s.date = Time.now.strftime "%Y-%m-%d"
  s.summary = "Minimalist dependency injection"
  s.description = "MinDI is minimalist in that it attempts to map concepts of DI into basic ruby constructs, rather than into a layer of specialized constructs."
  s.email = "vjoel@users.sourceforge.net"
  s.extra_rdoc_files = ["README.md", "COPYING"]
  s.files = Dir[
    "README.md", "COPYING", "Rakefile", "RELEASE-NOTES",
    "lib/**/*.rb",
    "examples/**/*.rb",
    "test/**/*.rb"
  ]
  s.test_files = Dir["test/*.rb"]
  s.homepage = "https://github.com/vjoel/mindi"
  s.license = "BSD"
  s.rdoc_options = [
    "--quiet", "--line-numbers", "--inline-source",
    "--title", "MinDI", "--main", "README.md"]
  s.require_paths = ["lib"]
end
