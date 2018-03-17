platform :ios, '9.0'

use_frameworks!

def shared_pods
    pod 'ModelMapper',              '~> 6.0'
    pod 'Moya/RxSwift',             '~> 9.0'
    pod 'Moya-ModelMapper/RxSwift', '~> 5.0'
    pod 'RxCocoa',                  '~> 3.0'
end

target 'CodeChallenge' do
    shared_pods
end

target 'CodeChallengeTests' do
    shared_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.2'
        end
    end
end
