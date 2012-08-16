Pod::Spec.new do |s|
  s.name         = "TransloaditAPIClient"
  s.version      = "0.0.1"
  s.summary      = "A Transloadit API client powered by AFNetworking."
  s.homepage     = "https://github.com/wilhelmbot/TransloaditAPIClient"
  s.license      = { :type => 'MIT', :file => 'License' }
  s.authors      = { "Rod Wilhelmy" => "rwilhelmy@gmail.com", "Felix Geisendörfer" => "felix.geisendoerfer@transloadit.com" }
  s.source       = { :git => "https://github.com/wilhelmbot/TransloaditAPIClient.git", :tag => "0.0.1" }
  s.platform     = :ios, '4.0'
  s.source_files = 'TransloaditAPIClient/*.{h,m}'
  s.public_header_files = 'TransloaditAPIClient/*.h'
  s.dependency 'AFNetworking'
end
