# Pageless Redirect Generator
#
# Generates redirect pages based on YAML or htaccess style redirects
#
# To generate redirects create _redirects.yml, _redirects.htaccess, and/or _redirects.json in the Jekyll root directory
# both follow the pattern alias, final destination.
#
# Example _redirects.yml
#
#   initial-page   : /destination-page
#   other-page     : http://example.org/destination-page
#   "another/page" : /destination-page
#
#  Result:
#   Requests to /initial-page are redirected to /destination-page
#   Requests to /other-page are redirected to http://example.org/destination-page
#   Requests to /another/page are redirected to /destination-page
#
#
# Example _redirects.htaccess
#
#   Redirect /some-page /destination-page
#   Redirect 301 /different-page /destination-page
#   Redirect cool-page http://example.org/destination-page
#
#  Result:
#   Requests to /some-page are redirected to /destination-page
#   Requests to /different-page are redirected to /destination-page
#   Requests to /cool-page are redirected to http://example.org/destination-page
#
#
# Example _redirects.json
#
#   {
#     "some-page"        : "/destination-page",
#     "yet-another-page" : "http://example.org/destination-page",
#     "ninth-page"       : "/destination-page"
#   }
#
#  Result:
#   Requests to /some-page are redirected to /destination-page
#   Requests to /yet-another-page are redirected to http://example.org/destination-page
#   Requests to /ninth-page are redirected to /destination-page
#
#
# Author: Nick Quinlan
# Site: http://nicholasquinlan.com
# Plugin Source: http://github.com/nquinlan/jekyll-pageless-redirect
# Plugin License: MIT
# Plugin Credit: This plugin borrows heavily from alias_generator (http://github.com/tsmango/jekyll_alias_generator) by Thomas Mango (http://thomasmango.com)

require 'json'

module Jekyll

  class PagelessRedirectGenerator < Generator

    def generate(site)
      @site = site

      process_yaml
      process_htaccess
      process_json
    end

    def process_yaml
      file_path = File.join(@site.source, "/_redirects.yml")
      if File.exists?(file_path)
        YAML.load_file(file_path, :safe => true).each do | new_url, old_url |
          generate_aliases( old_url, new_url )
        end
      end
    end

    def process_htaccess
      file_path = File.join(@site.source, "/_redirects.htaccess")
      if File.exists?(file_path)
        # Read the file line by line pushing redirects to the redirects array
        File.open(file_path, "r") do |file|
          while (line = file.gets)
            # Match the line against a regex, if it matches push it to the object
            /^Redirect(\s+30[1237])?\s+(.+?)\s+(.+?)$/.match(line) { | matches |
              generate_aliases(matches[3], matches[2])
            }
          end
        end
      end
    end

    def process_json
      file_path = File.join(@site.source, "/_redirects.json")
      if File.exists?(file_path)
        File.open(file_path, "r") do |file|
          content = JSON.parse(file.read)
          content.each do |a, b|
            generate_aliases(a, b)
          end
        end
      end

      # @site.static_files.each {|sf| puts sf.path}
    end

    def generate_aliases(destination_path, aliases)
      alias_paths = []
      alias_paths << aliases
      alias_paths.compact!

      alias_paths.flatten.each do |alias_path|
        alias_path = alias_path.to_s

        alias_dir  = File.dirname(alias_path) == "." ? "/" : File.dirname(alias_path)
        alias_file = File.extname(alias_path).empty? ? "index.html" : File.basename(alias_path)

        fs_path_to_dir   = File.absolute_path(File.join(@site.dest, alias_dir))
        alias_index_path = File.join(alias_dir, alias_file)

        FileUtils.mkdir_p(fs_path_to_dir)

        fs_alias_file = File.join(fs_path_to_dir, alias_file)
        File.open(fs_alias_file, 'w') do |file|
          file.write(alias_template(destination_path))
        end

        # alias_path_parts = alias_index_path.split('/')
        # if alias_path_parts.size > 2
        #   alias_path_parts.size.times do |sections|
        #     temp_path = alias_path_parts[0, sections].join('/')
        #     @site.static_files << Jekyll::PagelessRedirectFile.new(@site, @site.dest, temp_path, alias_path_parts[sections + 1])
        #   end
        # else
        #   @site.static_files << Jekyll::PagelessRedirectFile.new(@site, @site.dest, "/", alias_path_parts[-1])
        # end
        @site.static_files << Jekyll::PagelessRedirectFile.new(@site, @site.dest, alias_dir, alias_file)
      end
    end

    def alias_template(destination_path)
      <<-EOF
      <!DOCTYPE html>
      <html>
      <head>
      <link rel="canonical" href="#{destination_path}"/>
      <meta http-equiv="content-type" content="text/html; charset=utf-8" />
      <meta http-equiv="refresh" content="0;url=#{destination_path}" />
      </head>
      </html>
      EOF
    end
  end

  class PagelessRedirectFile < StaticFile
    require 'set'

    # def destination(dest)
    #   File.join(dest, @dir)
    # end

    def modified?
      return false
    end

    def write(dest)
      return true
    end
  end
end
