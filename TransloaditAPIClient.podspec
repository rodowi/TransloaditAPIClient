Pod::Spec.new do |s|
  s.name         = "TransloaditAPIClient"
  s.version      = "0.0.4"
  s.summary      = "A Transloadit API client powered by AFNetworking."
  s.homepage     = "https://github.com/citivox/TransloaditAPIClient"
  s.license      = { :type => 'MIT', :file => 'License' }
  s.authors      = { "Rod Wilhelmy" => "rodolfo@citivox.com", "Felix Geisendörfer" => "felix.geisendoerfer@transloadit.com" }
  s.source       = { :git => "https://github.com/citivox/TransloaditAPIClient.git", :tag => "0.0.4" }
  s.platform     = :ios, '4.0'
  s.source_files = 'TransloaditAPIClient/*.{h,m}'
  s.public_header_files = 'TransloaditAPIClient/*.h'
  s.dependency 'AFNetworking'
end
