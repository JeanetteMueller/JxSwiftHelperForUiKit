#
# Be sure to run `pod lib lint JxSwiftHelperForUiKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JxSwiftHelperForUiKit'
  s.version          = '0.1.0'
  s.summary          = 'A Collection of Extensions and Helper to work faster witz UIKit'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  UIColor+hexstring: colors from CSS Hexcode
  UIImage+grayScale: get image without color
  UIImage+resized: resize your images and cache them to the local filesystem
  UIImageView+LoadImage: download images from web, resize and store them localy
                       DESC

  s.homepage         = 'https://github.com/JeanetteMueller/JxSwiftHelperForUiKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JeanetteMueller' => 'themaverick@themaverick.de' }
  s.source           = { :git => 'https://github.com/JeanetteMueller/JxSwiftHelperForUiKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/JeanetteMueller'

#  s.ios.deployment_target = '11.0'

  s.source_files = 'Classes/*.swift'
  
  # s.resource_bundles = {
  #   'JxSwiftHelperForUiKit' => ['JxSwiftHelperForUiKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'JxSwiftHelper'
end
