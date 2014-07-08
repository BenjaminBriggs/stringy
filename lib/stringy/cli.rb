#!/usr/bin/env ruby

require 'thor'

module Stringy
  class CLI < Thor

    desc "update", "The main call that starts the stringification process"
    def update()
      puts "Wrong Directory" unless Dir.exists?("Base.lproj")

        @current_directory = Dir.pwd

        # Run Genstrings
        system('find ./ -name "*.m" -o -name "*.mm" -print0 | xargs -0 genstrings -o Base.lproj')

        # Set up some extentions
        storyboardExt = ".storyboard"
        stringsExt = ".strings"
        localeDirExt = ".lproj"

        isNewStringsFile = false

        # Loop the storyboards in base
        Dir.glob("Base.lproj/*#{storyboardExt}") do |storyboardPath|

          # Create the base path (eg. settings)
          baseStringsPath = storyboardPath.chomp(File.extname(storyboardPath)) + stringsExt

            # Check if it exists
            if Dir.exists?(baseStringsPath) then
              isNewStringsFile = false
            else
              # If it we need to create the file.
              puts baseStringsPath + " file doesn't exist; create"

              system('ibtool --export-strings-file', baseStringsPath ,storyboardPath)

              isNewStringsFile = true
            end

          # Create strings file only when storyboard file newer and not just been created
          if isNewStringsFile || `find #{storyboardPath} -prune -newer #{baseStringsPath} -print | grep -q .` then

            puts storyboardPath + " is modified; update " + baseStringsPath

            # Get storyboard file name and folder
            storyboardDir = File.dirname(storyboardPath)

            # Get New Base strings file full path and strings file name
            newBaseStringsPath = `echo "#{storyboardPath}" | sed "s/#{storyboardExt}/#{newStringsExt}/"`
            stringsFile = File.basename(baseStringsPath)

            system('ibtool --export-strings-file', newBaseStringsPath ,storyboardPath)

            system('iconv -f UTF-16 -t UTF-8', newBaseStringsPath, '>', baseStringsPath)

            Dir.rmdir(newBaseStringsPath)

            # Get all locale strings folder
            Dir.glob("*#{localeDirExt}") do |localeStringsDir|

              # Skip Base strings folder
              if localeStringsDir != storyboardDir then
                localeStringsPath = localeStringsDir+"/"+stringsFile

                # Just copy base strings file on first time
                if !Dir.exists?(localeStringsPath) then
                  FileUtils.cp(baseStringsPath, localeStringsPath)
                else
                  oldLocaleStringsPath= `echo "#{localeStringsPath}" | sed "s/#{stringsExt}/#{oldStringsExt}/"`
                  FileUtils.cp(localeStringsPath, oldLocaleStringsPath)

                  # Merge baseStringsPath to localeStringsPath
                  system(awk, 'NR == FNR && /^\/\*/ {x=$0; getline; a[x]=$0; next} /^\/\*/ {x=$0; print; getline; $0=a[x]?a[x]:$0; printf $0"\n\n"}', oldLocaleStringsPath, baseStringsPath, '>', localeStringsPath)

                  Dir.rmdir(oldLocaleStringsPath)
                end
              end
            end
          end
      end
    end
  end
end

