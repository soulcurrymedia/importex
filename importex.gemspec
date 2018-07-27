Gem::Specification.new do |s|
  s.name = "shanlalit-importex"
  s.summary = "Import an Excel document with Ruby."
  s.description = "Import an Excel document by creating a Ruby class and passing in an 'xls' file. It will automatically format the columns into specified Ruby objects and raise errors on bad data."
  s.homepage = "http://github.com/ryanb/importex"

  s.version = "0.9.0"
  s.date = "2018-05-11"

  s.authors = ["Ryan Bates", "Miles Z. Sterrett", "Lalit Shandilya", "brenes"]
  s.email = ["ryan@railscasts.com", "miles@mileszs.com", "shanlalit@gmail.com", "brenes@simplelogica.com"]

  s.require_paths = ["lib"]
  s.files = Dir["lib/**/*"] + Dir["spec/**/*"] + ["LICENSE", "README.rdoc", "Rakefile", "CHANGELOG.rdoc"]
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG.rdoc", "LICENSE"]

  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Importex", "--main", "README.rdoc"]

  s.add_dependency("spreadsheet", "~> 1.1.7")

  s.rubygems_version = "1.3.4"
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2")
end
