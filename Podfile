source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.0'
use_frameworks!

def library
   pod 'KissXML'
   pod 'KissXML/libxml_module'
   pod 'ICSMainFramework', :path => "./Library/ICSMainFramework/"
   pod 'MMWormhole', '~> 2.0.0'
end

def tunnel
    pod 'MMWormhole', '~> 2.0.0'
end

def socket
    pod 'CocoaAsyncSocket', '~> 7.4.3'
end

target "Potatso" do
    pod 'Aspects', :path => "./Library/Aspects/"
    pod 'Cartography'
    pod 'AsyncSwift'
    pod 'UMengAnalytics-NO-IDFA'
    pod 'SwiftColor', '~> 0.3.7'
    pod 'Appirater'
    pod 'Eureka', '~> 1.6.0'
    pod 'MBProgressHUD'
    pod 'CallbackURLKit'
    pod 'ICDMaterialActivityIndicatorView'
    pod 'Reveal-iOS-SDK', '~> 1.6.2', :configurations => ['Debug']
    pod 'ICSPullToRefresh', '~> 0.4'
    pod 'ISO8601DateFormatter', '~> 0.8'
    pod 'Alamofire'
    pod 'ObjectMapper'
    pod 'CocoaLumberjack/Swift'
    tunnel
    library
    socket
end

target "PacketTunnel" do
    tunnel
    socket
end

target "PacketProcessor" do
    socket
end

target "TodayWidget" do
    pod 'Cartography'
    pod 'SwiftColor'
    library
    socket
end

target "PotatsoLibrary" do
    library
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end

