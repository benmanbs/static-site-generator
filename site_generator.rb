template_file = Dir.pwd+'/template.html'
pages = Dir[Dir.pwd+'/pages/*']

titles = [];
combined_pages = []

page_to_titles = {}

pages.each{ |page|
	if File.directory?(page)
		dir_name = page.rpartition('/')[-1]
		current_pages = Dir[Dir.pwd+'/pages/'+dir_name+'/*']
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
	File.open(Dir.pwd+'/static_site/'+title+'.html', 'w') { |f| 
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
