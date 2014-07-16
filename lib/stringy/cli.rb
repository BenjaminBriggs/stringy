#!/usr/bin/env ruby

require 'thread'
require 'fileutils'
require 'thor'

Thread.abort_on_exception = true

module Stringy
  class CLI < Thor
    class_option :verbose, :type => :boolean, :aliases => "-v"
    class_option :force, :type => :boolean, :aliases => "-f"

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
        xibExt = ".xib"
        stringsExt = ".strings"
        localeDirExt = ".lproj"

        newStringsExt=".new"

        # Loop the storyboards in base
        Dir.glob("Base.lproj/*{#{storyboardExt},#{xibExt}}") do |storyboardPath|

          # Create the base path (eg. settings)
          baseStringsPath = storyboardPath.chomp(File.extname(storyboardPath)) + stringsExt

          puts "" if options[:verbose]
          puts "Starting " + baseStringsPath if options[:verbose]

          # Check if it exists
          stringFileIsMissing = !File.file?(baseStringsPath)
          if !stringFileIsMissing
            storyboardIsNewer = File.mtime(storyboardPath) > File.mtime(baseStringsPath)
          else
            storyboardIsNewer = false
          end

          puts "String file is missing" if options[:verbose] && stringFileIsMissing
          puts "Storyboard is newer" if options[:verbose] && storyboardIsNewer

          # Create strings file only when storyboard file newer and not just been created
          if options[:force] || stringFileIsMissing || storyboardIsNewer then

            puts "Updating " + baseStringsPath if options[:verbose]

            # Get storyboard file name and folder
            storyboardDir = File.dirname(storyboardPath)

            # Get New Base strings file full path and strings file name
            stringsFile = File.basename(baseStringsPath)
            newBaseStringsPath = "#{storyboardDir}/#{stringsFile}#{newStringsExt}"

            puts "Running: ibtool --export-strings-file #{newBaseStringsPath.chomp} #{storyboardPath.chomp}" if options[:verbose]
            system("ibtool --export-strings-file #{newBaseStringsPath.chomp} #{storyboardPath.chomp}"+warningSuppressor)

            puts "Running: iconv -f UTF-16 -t UTF-8 #{newBaseStringsPath.chomp} > #{baseStringsPath.chomp}" if options[:verbose]
            system("iconv -f UTF-16 -t UTF-8 #{newBaseStringsPath.chomp} > #{baseStringsPath.chomp}")
            
            FileUtils.rm(newBaseStringsPath) if File.exists?(newBaseStringsPath)

            if options[:overwrite] then
              # Get all locale strings folder
              Dir.glob("*#{localeDirExt}") do |localeStringsDir|

                # Skip Base strings folder
                if localeStringsDir != storyboardDir

                  localeStringsPath = localeStringsDir+"/"+stringsFile

                  puts "Move strings file in " + localeStringsPath if options[:verbose]
                  FileUtils.mkdir_p(File.dirname(localeStringsPath))
                  FileUtils.cp(baseStringsPath, localeStringsPath)
                end
              end
            end
          else
            puts "No action needed" if options[:verbose]
          end
      end
      
      puts "" #just to add a line for formating
    end
  end
end
