platform :ios, '9.0' # minimum required by Alamofire 4

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
