platform :ios, '7.0'
source 'https://github.com/CocoaPods/Specs.git'

abstract_target :Shared do
  pod 'ComponentKit', '0.14'

  target :CKToolbox

  target :TableViewDemo do
    pod 'CKToolbox/TableViewDataSource', :path => '.'
  end

  target :Tests do
    pod 'CKToolbox', :path => '.'
    pod 'OCMock', '~> 3.2.2'
    pod 'Specta', '~> 1.0.5'
    pod 'Expecta', '~> 1.0.5'
    pod 'ComponentSnapshotTestCase', :podspec => 'Support/ComponentSnapshotTestCase.podspec'
  end
end

inhibit_all_warnings!
