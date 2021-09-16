# Uncomment the next line to define a global platform for your project
platform :ios, '12.1'

target 'Currency Converter' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Currency Converter

  pod 'Moya/RxSwift'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'iOSDropDown'

  post_install do |pi|
      pi.pods_project.targets.each do |t|
        t.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.1'
        end
      end
  end
  
  target 'Currency ConverterTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Currency ConverterUITests' do
    # Pods for testing
  end

end
