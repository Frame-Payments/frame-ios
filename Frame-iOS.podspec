Pod::Spec.new do |s|
  s.name             = 'Frame-iOS'
  s.version          = '3.0.0'
  s.summary          = 'The Frame Payments iOS SDK.'
  s.description      = <<-DESC
    Frame Payments iOS SDK. Provides payments, networking, theming, and a
    drop-in checkout experience. For onboarding (KYC, identity, bank linking),
    see the companion Frame-Onboarding pod.
  DESC
  s.homepage         = 'https://github.com/Frame-Payments/frame-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Frame Payments' => 'engineering@framepayments.com' }
  s.source           = { :git => 'https://github.com/Frame-Payments/frame-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '17.0'
  s.swift_versions   = ['5.10']
  s.static_framework = true

  s.source_files     = 'Sources/Frame/**/*.swift'
  s.resource_bundles = {
    'Frame' => ['Sources/Frame/Resources/**/*']
  }

  s.dependency 'Frame-EvervaultCore', '~> 2.1.0-frame.2'
  s.dependency 'Frame-EvervaultInputs', '~> 2.1.0-frame.2'
  s.dependency 'Sift', '~> 2.2'
  s.dependency 'FingerprintPro', '~> 2.15'
  s.dependency 'PhoneNumberKit', '~> 4.2'
end
