inhibit_all_warnings!

def import_pods
  pod 'OCMock', '2.1.1'
  pod 'Expecta', '0.2.1'
end

target :ios do
  platform :ios, '5.0'
  link_with 'AFNetworkingTests'
  import_pods
end

target :osx do
  platform :osx, '10.7'
  link_with 'AFNetworkingFrameworkTests'
  import_pods
end
