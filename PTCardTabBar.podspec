#
# Be sure to run `pod lib lint PTCardTabBar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PTCardTabBar'
  s.version          = '0.1.0'
  s.summary          = 'A short description of PTCardTabBar.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  A Simple Card style tab bar with only displaying icons with small circle under the selected tab bar, try it :)


                       DESC

  s.homepage         = 'https://github.com/hussc/PTCardTabBar'
  s.screenshots     = 'https://imgur.com/t0BXUKL', 'https://imgur.com/HRHUEAd'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hussc' => 'hus.sc@aol.com' }
  s.source           = { :git => 'https://github.com/hussc/PTCardTabBar.git', :tag => s.version.to_s }
  s.social_media_url = 'https://www.facebook.com/hussc'

  s.ios.deployment_target = '8.0'

  s.source_files = 'PTCardTabBar/Classes/**/*'
  
  # s.resource_bundles = {
  #   'PTCardTabBar' => ['PTCardTabBar/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
