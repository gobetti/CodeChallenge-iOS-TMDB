platform :ios, '9.0'

use_frameworks!

def shared_pods
    pod 'Moya/RxSwift',             '~> 11.0'
    pod 'RxCocoa',                  '~> 4.0'
end

target 'CodeChallenge' do
    shared_pods
end

target 'CodeChallengeTests' do
    shared_pods
    pod 'RxTest' # follows RxCocoa's version
end
