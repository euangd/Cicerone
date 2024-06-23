$macOSVersion = '13.3'
$NATIVE_ARCH=arm64

platform :macos, $macOSVersion, $NATIVE_ARCH
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
    def customize_build (build)
      build['ARCHS'] = '$(NATIVE_ARCH)' # set to native architecture
      build['DEPLOYMENT_POSTPROCESSING'] = 'YES'
      build['ONLY_ACTIVE_ARCH'] = 'YES'
      build['MACOSX_DEPLOYMENT_TARGET'] = $macOSVersion # not sure if targets inherit specified platform in an accessible way from an abstract_target ancestor
    end
  
    project.build_configurations.each do |configuration|
      customize_build configuration.build_settings
    end
  
    project.targets.each do |target|
      target.build_configurations.each do |configuration|
        customize_build configuration.build_settings
      end
    end
  end
end
