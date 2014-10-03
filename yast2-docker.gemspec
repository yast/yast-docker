Gem::Specification.new do |spec|

  # gem name and description
  spec.name     = "yast2-docker"
  spec.version  = "3.1.0"
  spec.summary  = "YaST2 - GUI for docker management"
  spec.license  = "GPL-2.0 or GPL-3.0"
  spec.authors  = ["Flavio Castelli", "Josef Reidinger"]
  spec.homepage = "http://github.org/yast/yast-docker"

  # gem content
  spec.files   = Dir[
    "doc/*.png", "src/**/*.rb", "src/desktop/*.desktop",
    "test/*.rb", "README.md"
  ]

  # define LOAD_PATH
  spec.require_path = "src/lib"

  # dependencies
  spec.add_dependency "docker-api"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "yast-rake"
end
