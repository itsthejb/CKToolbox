Pod::Spec.new do |s|
	# Versions here
  s.version                  = "0.1.0"
  s.dependency 'ComponentKit', "~> 0.0"

  s.name          = 'CKToolbox'	
  s.summary       = 'A toolbox library for ComponentKit'
  s.description   = 'A suite of helpers and features for working with Facebook ComponentKit'
  s.homepage      = 'https://github.com/itsthejb/CKToolbox'
  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.authors       = { 'Jonathan Crooke' => 'jon.crooke@gmail.com' }
  s.source        = { :git => 'https://github.com/itsthejb/CKToolbox.git', :tag => "v#{s.version.to_s}" }
  s.ios.deployment_target = '7.0'
  s.frameworks    = 'UIKit'

	s.subspec 'All' do |sp|
  	sp.dependency 'CKToolbox/ChangesetBuilder'
    sp.dependency 'CKToolbox/TableViewDataSource'
    sp.dependency 'CKToolbox/RemoveAll'
	end

	s.subspec 'ChangesetBuilder' do |sp|
		sp.source_files = 'Modules/ChangesetBuilder/*.{h,m,mm}'
	end

  s.subspec 'TableViewDataSource' do |sp|
    sp.source_files = 'Modules/TableViewDataSource/*.{h,m,mm}'
    sp.dependency 'CKToolbox/RemoveAll'
  end

  s.subspec 'RemoveAll' do |sp|
    sp.source_files = 'Modules/RemoveAll/*.{h,m,mm}'
  end
end
