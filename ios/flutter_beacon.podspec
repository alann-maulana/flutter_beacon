#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_beacon'
  s.version          = '0.3.0'
  s.summary          = 'Flutter plugin for scanning beacon (iBeacon platform) devices on Android and iOS.'
  s.description      = <<-DESC
Flutter plugin for scanning beacon (iBeacon platform) devices on Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/alann-maulana/flutter_beacon'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Eyro Labs' => 'maulana@cubeacon.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'
  s.ios.framework = 'CoreLocation',
                    'CoreBluetooth'
end

