platform :ios, '9.0'

use_frameworks!

def shared_pods
    pod 'RxCocoaNetworking'
end

target 'CodeChallenge' do
    shared_pods
end

target 'CodeChallengeTests' do
    shared_pods
    pod 'RxTest' # follows RxCocoa's version
end

post_install do |installer|
   installer.pods_project.targets.each do |target|
      if target.name == 'RxSwift'
         target.build_configurations.each do |config|
            if config.name == 'Debug'
               config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['-D', 'TRACE_RESOURCES']
            end
         end
      end
   end
end
