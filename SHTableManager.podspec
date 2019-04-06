Pod:: Spec.new do |spec|
  spec.platform     = 'ios', '10.0'
  spec.name         = 'SHTableManager'
  spec.version      = '1.0.9'
  spec.summary      = 'A framework for managing UITableViews'
  spec.author = {
    'Susmita Horrow' => 'susmita.horrow@gmail.com'
  }
  spec.license          = 'MIT'
  spec.homepage         = 'https://github.com/hsusmita/TableManager'
  spec.source = {
    :git => 'https://github.com/hsusmita/TableManager.git',
    :tag => '1.0.9'
  }
  spec.ios.deployment_target = '10.0'
  spec.requires_arc = true
  spec.swift_version = '4.2'  
  spec.source_files = 'TableManager/Source/*'
  spec.dependency 'DeepDiff'
end
