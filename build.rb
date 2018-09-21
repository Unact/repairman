
puts "------------------- start build --------------------------------"
raise "build ios error" unless system("flutter build ios --release")

raise "build android error" unless system("flutter build apk --release")

puts "------------------ start ios archive ---------------------------"

raise "archive ios error" unless system("xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
clean archive -configuration release -sdk iphoneos \
-archivePath build/ios/iphoneos/Runner.xcarchive")

raise "create ipa error" unless system("xcodebuild -exportArchive -archivePath build/ios/iphoneos/Runner.xcarchive \
-exportOptionsPlist ios/ExportOptions.plist \
-exportPath  build/ios/iphoneos/Runner.ipa")

puts "------------------ copy to unact.github.io ---------------------------"

raise "shell error" unless system("cd ../unact.github.io/; \
git reset --hard; git pull; \
mv ../repairman/build/app/outputs/apk/release/app-release.apk . ; \
mv ../repairman/build/ios/iphoneos/Runner.ipa/Runner.ipa .")
