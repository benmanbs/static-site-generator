require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: site_generator.rb [options]"

  opts.on("-t", "--template_file FILE", "Template file to use. Should contain \"{{HEADER}}\" for the title and \"{{CONTENT}}\" for the content") do |t|
    options[:template_file] = t
  end

  opts.on("-p", "--page_directory DIRECTORY", "Directory of the files to be generated. Should contain a list of files looking like \"01_contact_us.page\"") do |d|
    options[:pages] = d.sub(/\/$/,'') # remove a trailing space if there is one
  end

  opts.on("-o", "--output_directory DIRECTORY", "Output directory generated files will be placed into") do |d|
    options[:output] = d.sub(/\/$/,'') # remove a trailing space if there is one
  end

end.parse!

if !options[:template_file] || !options[:pages] || !options[:output]
	raise "Missing options. Run with --help for the documentation"
end

template_file = options[:template_file]
pages = Dir[options[:pages]+'/*']

titles = [];
combined_pages = []

page_to_titles = {}

pages.each{ |page|
	if File.directory?(page)
		dir_name = page.rpartition('/')[-1]
		current_pages = Dir[options[:pages]+'/'+dir_name+'/*']
		titles << {
			:page => dir_name,
			:subpages => current_pages.map{ |curr_page| 
				page_to_titles[curr_page] = dir_name+"/"+curr_page.rpartition('/')[-1].rpartition('.')[0]
				combined_pages << curr_page
				curr_page.rpartition('/')[-1].rpartition('.')[0]
			}
		}
	else
		combined_pages << page
		page_to_titles[page] = page.rpartition('/')[-1].rpartition('.')[0]
		titles << {:page => page.rpartition('/')[-1].rpartition('.')[0]}
	end
}

def make_title_pretty(title)
	# Take the number out of it
	title = remove_number_from_title(title)
	# convert underscore case to normal spaces
	title.gsub(/(^.|_.)/) { |s| s.gsub(/_/,' ').upcase }
end

def remove_number_from_title(title)
	title.match(/^\d*_(.*)/)[1]
end

def generate_titles(active_title, titles) 
	output = ''

	titles.each { |title| 
		html = '<li{{ACTIVE}}>
			          <a href="{{HREF}}">{{LINK}}</a>{{SUBPAGE}}
			        </li>'
		html.gsub!('{{ACTIVE}}', active_title == title[:page] ? ' class="active"' : '')
		if title[:subpages]
			html.gsub!('{{HREF}}', '#')
			text = "<ul>\n"
			title[:subpages].each{ |subpage| 
				text << "<li><a href=\""+remove_number_from_title(subpage)+".html\">"+make_title_pretty(subpage)+"</a></li>\n"
			}
			text << "</ul>"
			html.gsub!('{{SUBPAGE}}', text)
		else
			html.gsub!('{{HREF}}', "#{remove_number_from_title(title[:page])}.html")
			html.gsub!('{{SUBPAGE}}','')
		end
		html.gsub!('{{LINK}}', "#{make_title_pretty(title[:page])}")
		output << html + "\n"
	}

	output
end

combined_pages.each { |page|
	title = page_to_titles[page]

	# Clean up the title
	if title =~ /\//
		title = title.rpartition('/')[-1]
	end
	title = remove_number_from_title(title)

	# Create the static html page
	File.open(options[:output]+'/'+title+'.html', 'w') { |f| 
		content = ""
		# Open up the content file
		File.open(page, 'r') { |file|
			file.each_line { |line|
				content << line+"\n"
			}
		}

		# Open up the template file
		File.open(template_file, 'r') { |file|
			file.each_line { |line|
				if line =~ /\{\{HEADER\}\}/
					f.write(generate_titles(title, titles))
				elsif line =~ /\{\{CONTENT\}\}/
					f.write(content)
				else
					f.write(line)
				end
			}
		}
	}
}
