#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_beacon'
  s.version          = '0.1.0'
  s.summary          = 'An hybrid iBeacon scanner SDK for Flutter plugin.'
  s.description      = <<-DESC
An hybrid iBeacon scanner SDK for Flutter plugin.
                       DESC
  s.homepage         = 'https://github.com/alann-maulana/flutter_beacon'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Alann Maulana' => 'alann.maulana@outlook.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'
  s.ios.framework = 'CoreLocation',
                    'CoreBluetooth'
end

