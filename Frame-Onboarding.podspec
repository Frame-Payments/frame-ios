Pod::Spec.new do |s|
  s.name             = 'Frame-Onboarding'
  s.version          = '3.0.0'
  s.summary          = 'Onboarding flows (KYC, identity, bank linking) for the Frame Payments iOS SDK.'
  s.description      = <<-DESC
    Frame Onboarding builds on the Frame-iOS core SDK and adds onboarding
    flows: identity verification (Prove), bank linking (Plaid), phone OTP,
    and 3DS verification.

    NOTE: This pod depends on `ProveAuth`, which is distributed via Prove's
    private CocoaPods Artifactory spec repo. Consumers must install the
    `cocoapods-art` plugin and register Prove's source before `pod install`.
    See the project README for setup instructions.
  DESC
  s.homepage         = 'https://github.com/Frame-Payments/frame-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Frame Payments' => 'engineering@framepayments.com' }
  s.source           = { :git => 'https://github.com/Frame-Payments/frame-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '17.0'
  s.swift_versions   = ['5.10']
  s.static_framework = true

  s.source_files     = 'Sources/FrameOnboarding/**/*.swift'

  s.dependency 'Frame-iOS', "= #{s.version}"
  s.dependency 'ProveAuth', '~> 6.10'
  s.dependency 'Plaid', '~> 6.4'
end
