#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_tinkoff_acquiring.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_tinkoff_acquiring'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
  A package to implement Tinkoff Acquiring Mobile SDK for both Android and iOS
                       DESC
  s.homepage         = 'https://bizapp.ru'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BizApp LLC' => 'kluchic@gamil.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'TinkoffASDKCore'
  s.dependency 'TinkoffASDKUI'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
