platform :ios, '7.0'

CK_VERS='0.14'.freeze

target :CKToolbox do
  pod 'ComponentKit', CK_VERS
end

target :TableViewDemo do
  pod 'CKToolbox/TableViewDataSource', :path => '.'
end

target :Tests do
  pod 'CKToolbox/All', :path => '.'
  pod 'OCMock', '~> 3.2.2'
  pod 'Specta', '~> 1.0.5'
  pod 'Expecta', '~> 1.0.5'
  pod 'ComponentSnapshotTestCase', :podspec => 'Support/ComponentSnapshotTestCase.podspec'
end

inhibit_all_warnings!
