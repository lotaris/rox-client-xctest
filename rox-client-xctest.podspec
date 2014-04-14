Pod::Spec.new do |s|
  s.name             = "rox-client-xctest"
  s.version          = "0.1.1"
  s.summary          = "XCTest client for ROX Center."
  s.description      = <<-DESC
                       XCTest client for ROX Center.
                       This project contains a category (RoxTest) of XCTestCase and a subclass of XCTestObserver.
                       The RoxTest category of XCTestCase has public properties and methods to set ROX Center specific information for a test or a class of tests.
                       It also register the subclass of XCTestObserver (RoxTestObserver) as a listener of the test run.
                       Preferences related to ROX are read from ~/.rox/config.yml so rox-client-xctest has a dependency to the YAML framework.
                       Results are sent to the ROX Center server as a JSON payload (more info in ROX Center API)
                       DESC
  s.homepage         = "http://github.com/lotaris/rox-client-xctest"
  s.license          = 'MIT'
  s.author           = { "Francois Vessaz" => "francois.vessaz@lotaris.com" }
  s.source           = { :git => "https://github.com/lotaris/rox-client-xctest.git", :tag => s.version.to_s }

  s.requires_arc = true
  s.source_files = 'Classes/**/*.{h,m}'

  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  s.public_header_files = 'Classes/**/*.h'
  s.frameworks = 'XCTest'
  s.dependency 'YAML-Framework', '~> 0.0.2'
end
