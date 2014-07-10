#!/usr/bin/env ruby

require 'thread'
require 'fileutils'
require 'thor'

Thread.abort_on_exception = true

module Stringy
  class CLI < Thor
    class_option :verbose, :type => :boolean, :aliases => "-v"

    method_option :overwrite, :type => :boolean, :aliases => "-o"
    desc "update -v -o", "Updates then base stings and optionaly overwrites the tranlations"
    def update()
      
      if !Dir.exists?("Base.lproj")    
        puts "Wrong directory please select the directory that contains the Base.lproj folder" 
        return
      end
      
        if !options[:verbose] then
          Thread.new do
            #set up spinner
            glyphs = ['|', '/', '-', "\\"]
            while true
              glyphs.each do |g|
                print "\r#{g}"
                sleep 0.15
              end
            end
          end
        end
        
        warningSuppressor = options[:verbose]? "" : " > /dev/null 2>&1"

        # Run Genstrings
        puts "running genstrings" if options[:verbose]
        system('find ./ -name "*.m" -o -name "*.mm" -print0 | xargs -0 genstrings -o Base.lproj'+warningSuppressor)

        # Set up some extentions
        storyboardExt = ".storyboard"
        stringsExt = ".strings"
        localeDirExt = ".lproj"

        newStringsExt=".strings.new"

        isNewStringsFile = false

        # Loop the storyboards in base
        Dir.glob("Base.lproj/*#{storyboardExt}") do |storyboardPath|

          # Create the base path (eg. settings)
          baseStringsPath = storyboardPath.chomp(File.extname(storyboardPath)) + stringsExt

          puts "" if options[:verbose]
          puts "Starting " + baseStringsPath if options[:verbose]

          # Check if it exists
          if File.file?(baseStringsPath)
            isNewStringsFile = false
          else
            # If it we need to create the file.
            puts baseStringsPath + " file doesn't exist; create" if options[:verbose]
            puts "Running: ibtool --export-strings-file #{baseStringsPath.chomp} #{storyboardPath.chomp}" if options[:verbose]
            system("ibtool --export-strings-file #{baseStringsPath.chomp} #{storyboardPath.chomp}"+warningSuppressor)

            puts baseStringsPath + " file created" if options[:verbose]

            isNewStringsFile = true
          end

          # Create strings file only when storyboard file newer and not just been created
          if isNewStringsFile || `find #{storyboardPath.chomp} -prune -newer #{baseStringsPath.chomp} -print | grep -q .` then

            puts storyboardPath + " is modified; update " + baseStringsPath if options[:verbose]

            # Get storyboard file name and folder
            storyboardDir = File.dirname(storyboardPath)

            # Get New Base strings file full path and strings file name
            newBaseStringsPath = `echo "#{storyboardPath}" | sed "s/#{storyboardExt}/#{newStringsExt}/"`.chomp
            stringsFile = File.basename(baseStringsPath)

            if isNewStringsFile == false
              puts "Running: ibtool --export-strings-file #{newBaseStringsPath.chomp} #{storyboardPath.chomp}" if options[:verbose]
              system("ibtool --export-strings-file #{newBaseStringsPath.chomp} #{storyboardPath.chomp}"+warningSuppressor)

              puts "Running: iconv -f UTF-16 -t UTF-8 #{newBaseStringsPath.chomp} > #{baseStringsPath.chomp}" if options[:verbose]
              system("iconv -f UTF-16 -t UTF-8 #{newBaseStringsPath.chomp} > #{baseStringsPath.chomp}"+warningSuppressor)
            end

            FileUtils.rm(newBaseStringsPath) if File.exists?(newBaseStringsPath)

            if options[:overwrite] then
              # Get all locale strings folder
              Dir.glob("*#{localeDirExt}") do |localeStringsDir|

                # Skip Base strings folder
                if localeStringsDir != storyboardDir

                  localeStringsPath = localeStringsDir+"/"+stringsFile

                  puts "Move strings file in " + localeStringsDir if options[:verbose]
                  FileUtils.mkdir_p(File.dirname(localeStringsPath))
                  FileUtils.cp(baseStringsPath, localeStringsPath)
                end
              end
            end
          end
      end
      
      puts "" if !options[:verbose]
    end
  end
end
