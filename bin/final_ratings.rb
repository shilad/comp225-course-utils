require_relative 'course'
require_relative 'questionnaire'

questions = [
  MemberOpenAnswer.new("Who did what?"),
  MemberScale.new("Quality of work"),
  OpenAnswer.new("Comments on quality"),
  MemberScale.new("Quantity of work"),
  OpenAnswer.new("Comments on quantity"),
  MemberScale.new("Initiative, creativity, expertise, leadership"),
  OpenAnswer.new("Comments on initiative etc."),
  MemberScale.new("Dependability and commitments"),
  OpenAnswer.new("Comments on dependability etc."),
  MemberScale.new("Interaction, communication, support for others"),
  OpenAnswer.new("Comments on interaction etc."),
  MemberOpenAnswer.new("Overall thoughts on teammates") { |answers| answers.rotate(-1) },  # Self is last in questionnaire
  OpenAnswer.new("Final thoughts"),
]

course = read_course

puts "#{course.students.count} students"

ratings_file = data_file("Comp 225 Team self-assessment 2019.0 (Responses) - Form Responses 1.csv")
missing = Set.new(course.students)
CSV.foreach(ratings_file, headers: :first_row) do |row|
  student = course.student_with_email(row.fetch("Email Address"))
  missing.delete(student)
  
  teammates = (1...MAX_TEAM_SIZE).map do |i|
    name = row.fetch("Team member ##{i}’s name")
    next if [nil, "no one", "none", "nope", "na", "n/a", "null", "the void"].include?(name&.downcase)
    student.team.member_named(name)
  end
  rated_students = [student] + teammates.compact

  puts "#{student.first_name} → #{rated_students.map(&:first_name)}"

  cols = row[7..-1]
  questions.each do |question|
    question.read_response(student, rated_students, cols)
  end
end

course.teams.each do |team|
  outfile = "/tmp/#{team.section} #{team.name}.html"
  render_haml('results', outfile,
    team: team, questions: questions,
    title: "team self-assessment")
  `open "#{outfile}"`
end

begin
  total = course.students.size
  completed = total - missing.size
  puts
  puts "#{completed} / #{total} (#{(completed * 100.0 / total).round}%) questionnaires completed"
  puts

  puts "Completed teams:"
  course.teams.each do |team|
    if (team.members & missing).empty?
      puts "    #{team.name}"
    end
  end
  puts

  if missing.any?
    puts "Missing ratings from:"
    puts
    missing.group_by { |s| s.team.section }.each do |section, students|
      puts "  Section #{section}"
      puts
      students.each do |student|
        puts "    #{student.full_name.inspect} <#{student.email}>,"
      end
      puts
    end
  end
end
