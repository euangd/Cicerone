macOSVersion = '13.3'

platform :macos, macOSVersion
workspace 'Cicerone'

target 'Cicerone' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Cicerone
  
  pod 'PXSourceList', :git => 'https://github.com/brunophilipe/PXSourceList.git'
  pod 'DCOAboutWindow'
  pod 'Sparkle'

  target 'CiceroneTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |configuration|
        # configuration.build_settings['ARCHS'] = '$(NATIVE_ARCH)' # consider locking to Apple Silicon (arm64), or NATIVE_ARCH
        configuration.build_settings['DEPLOYMENT_POSTPROCESSING'] = 'YES'
        configuration.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        configuration.build_settings['MACOSX_DEPLOYMENT_TARGET'] = macOSVersion # not sure if targets inherit specified platform in an accessible way from an abstract_target ancestor
      end
    end
  end
end
