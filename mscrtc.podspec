#
# Be sure to run `pod lib lint storyboards-sample.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "mscrtc"
  s.version          = "0.0.1"
  s.summary          = "MSCRTC - WebRTC functions for mscrtc-ios"
  s.description      = <<-DESC
                       This pod add WebRTC functions to an app. 
                       It works together with the msc-kurento mediaserver implementation in Java
                       DESC
  s.homepage         = "https://github.com/inspiraluna/AppRTC-iOS"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Nico Krause" => "nico@le-space.de" }
  s.source           = { :git => "https://github.com/inspiraluna/AppRTC-iOS.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.1'
  s.requires_arc = true
  s.dependency  'thrift'
  s.dependency  'WebRTC'
  s.dependency  'SocketRocket'
  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'mscrtc' => ['Pod/**/*.{lproj,storyboard,xcassets}']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
