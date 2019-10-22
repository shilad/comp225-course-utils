require_relative 'course'
require_relative 'questionnaire'

course = read_course

def make_placeholder_file(name, template)
  outfile = File.join(projects_dir, '..', 'Project feedback', 'raw', "#{name}.md")
  if File.exist?(outfile)
    puts "#{outfile} already exists"
    return
  end

  puts outfile
  File.write(outfile, template.gsub(/^ +/, ''))
end

section_filter = ENV['section']
course.teams.each do |team|
  next if section_filter && team.section != section_filter

  make_placeholder_file team.name, <<-__EOS__
    ## The User’s Experience
    ​
    •••
    ​
    ## Code and Other Internals
    ​
    •••
    ​
    ## Demo
    ​
    •••
    ​
    ## Final Thoughts
    ​
    •••
    ​
    {grade}
  __EOS__

  team.members.each do |member|
    make_placeholder_file "#{team.name} - #{member.full_name}", <<-__EOS__
      #{member.first_name} —
      ​
      •••
      ​
      {grade}
  __EOS__
  end
end
