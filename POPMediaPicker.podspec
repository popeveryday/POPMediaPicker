Pod::Spec.new do |s|
s.name             = "POPMediaPicker"
s.version          = "0.1.47"
s.summary          = "Image/Video picker with capture/record buttons for Object-c project."
s.homepage         = "https://github.com/popeveryday/POPMediaPicker"
s.license          = 'MIT'
s.author           = { "popeveryday" => "popeveryday@gmail.com" }
s.source           = { :git => "https://github.com/popeveryday/POPMediaPicker.git", :tag => s.version.to_s }
s.platform     = :ios, '7.1'
s.requires_arc = true
s.source_files = 'Pod/Classes/**/*.{h,m,c}'
s.resources = 'Pod/Classes/**/*.bundle'
s.dependency 'POPLib', '~> 0.1'
s.dependency 'POPOrientationNavigationVC', '~> 0.1'
s.dependency 'MBProgressHUD', '~> 1.0'
end
