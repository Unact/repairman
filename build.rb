require 'yaml'
require 'github_api'
require 'dotenv/load'

raise "version not set" if ARGV[0].nil? || ARGV[0] == ""

pubspec = YAML.load_file('pubspec.yaml')

old_version = pubspec["version"][0...pubspec["version"].index('+')]
new_version = ARGV[0]

text = File.read('pubspec.yaml')
new_contents = text.gsub("version: #{old_version}", "version: #{new_version}")
File.write('pubspec.yaml', new_contents)

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
raise "git add error" unless system("git add pubspec.yaml")
raise "git commit error" unless system("git commit -m '#{new_version}'")
raise "git push error" unless system("git push")

text = File.read('../unact.github.io/manifest.plist')
new_contents = text.gsub(old_version, new_version)
File.write('../unact.github.io/manifest.plist', new_contents)

text = File.read('../unact.github.io/index.html')
new_contents = text.gsub(old_version, new_version)
File.write('../unact.github.io/index.html', new_contents)

github = Github.new basic_auth: ENV['TOKEN']

release = github.repos.releases.create 'unact', 'repairman', tag_name: new_version

github.repos.releases.assets.upload 'unact', 'repairman', release["id"],
   '../repairman/build/ios/iphoneos/Runner.ipa/Runner.ipa',
    name: "Runner.ipa",
   content_type: "application/octet-stream"

github.repos.releases.assets.upload 'unact', 'repairman', release["id"],
      '../repairman/build/app/outputs/apk/release/app-release.apk',
       name: "app-release.apk",
      content_type: "application/octet-stream"
