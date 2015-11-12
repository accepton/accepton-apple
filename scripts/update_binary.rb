#Go into the folder above this script (root project)
Dir.chdir File.join(File.dirname(__FILE__), "..")

#Build scripts
raise "build failed" unless system "./scripts/build_universal"

#Load podspec file
podspec_src = File.read("accepton.podspec")

#Increment version
podspec_src = podspec_src.split("\n")
podspec_src.map! do |line|
  next line unless line =~ /s\.version.*?=/

  #Get X.X.X version numbers in array
  version_nums = (line.scan /s\.version.*=.*"(\d+?)\.(\d+?)\.(\d+?)"/).first

  #Add 1 to last digit
  version_nums[-1] = (version_nums[-1].to_i+1).to_s
  version_nums_str = %{"#{version_nums.join(".")}"}
  @version_nums_str = version_nums.join(".")

  line = line.gsub /".*"/, version_nums_str
  next line
end

File.write("accepton.podspec", podspec_src.join("\n"))

#Update git repo with tag
system "git add ."
system "git commit -a -m #{@version_nums_str}"
system "git tag v#{@version_nums_str}"
