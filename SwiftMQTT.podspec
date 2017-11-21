
Pod::Spec.new do |s|
    
    s.name         = "SwiftMQTT"
    s.version      = "1.0.2"
    s.summary      = "MQTT Client in pure swift"
    s.description  = <<-DESC
    MQTT Client in pure swift
    DESC
    
    s.homepage     = "https://github.com/aciidb0mb3r/SwiftMQTT"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Ankit Agarwal" => "ankit.spd@gmail.com" }
    s.source       = { :git => "https://github.com/aciidb0mb3r/SwiftMQTT.git", :tag => s.version.to_s }
    
    s.ios.deployment_target = "8.0"
    s.osx.deployment_target = "10.10"
    s.tvos.deployment_target = "9.0"

    s.source_files  = "SwiftMQTT/SwiftMQTT/**/*.swift"

    s.frameworks  = "Foundation"
    
end
