Dir.chdir File.dirname(__FILE__) do
  #Build the frameworks
  #raise "Could not build frameworks" unless system("./build_universal")

  new_version = nil

  #Increment the version number in the podspec
  Dir.chdir "../" do
    podspec = File.read "accepton.podspec"
    new_podspec = podspec.split("\n").map do |line|
      if line =~ /s\.version[ ]*=[ ]*?/
        #Split it into ['  s.version = ', '0.1.1']
        components = line.split('"')

        #Split version from '0.1.1' => [0, 1, 1]
        #and increment the minor number
        version = components[1].split(".").map{|e| e.to_i}
        version[-1] += 1
        new_version = version.join(".") 
        components[1] = new_version

        output = components.join('"')
        output += '"'
        next output
      end

      next line
    end

    File.write "accepton.podspec", new_podspec.join("\n")

    #Updated Example podspec version
    Dir.chdir "Example" do
      system "pod install"
    end

    #Add changes to git
    system %{
      git add .
      git commit -a -m "Updated podspec to #{new_version}"
      git tag "#{new_version}"
      git push
      git push --tags
    }

    system %{
      pod trunk push --verbose --allow-warnings
    }
  end
end
