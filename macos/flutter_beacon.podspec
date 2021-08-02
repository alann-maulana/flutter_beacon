#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_beacon.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_beacon'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for scanning beacon (iBeacon platform) devices on Android, iOS and MacOS.'
  s.description      = <<-DESC
Flutter plugin for scanning beacon (iBeacon platform) devices on Android, iOS and MacOS.
                       DESC
  s.homepage         = 'https://github.com/alann-maulana/flutter_beacon'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Eyro Labs' => 'maulana@cubeacon.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files     = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'
  s.dependency 'ReactiveCocoa'
  s.dependency 'BlocksKit'
  s.dependency 'libextobjc'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
