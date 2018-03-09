require_relative 'course'
require_relative 'questionnaire'

# Midterm questions

questions = [
  SingleScale.new("How much fun are you having working on your project?"),
  SingleScale.new("What’s your feeling right now about how the project will turn out at the end of the semester?"),
  MemberScale.new("This team member is reliable."),
  MemberScale.new("This team member contributes important work."),
  MemberScale.new("This team member works hard."),
  MemberScale.new("This team member helps create a positive team dynamic."),
  OpenAnswer.new("What is your team doing well?"),
  OpenAnswer.new("What would you like your team to do better? (You can talk about specific individuals, or about the group as a whole.)"),
  OpenAnswer.new("Any other comments you’d like to share about the class, your team, or your project?"),
]

course = read_course

puts "#{course.students.count} students"

ratings_file = data_file("Comp 225 Midterm self-assessment 2017 fall (Responses) - Form Responses 1.csv")
CSV.foreach(ratings_file, headers: :first_row) do |row|
  next if row.to_h.values.compact.empty?  # skip blank rows

  student = course.student_with_email(row.fetch("Email Address"))
  
  teammates = (1...MAX_TEAM_SIZE).map do |i|
    name = row.fetch("Teammate #{i} name")
    next if [nil, "no one", "none", "n/a", "null"].include?(name&.downcase)
    student.team.member_named(name)
  end
  rated_students = teammates + [student]

  puts "#{student.first_name} → #{rated_students.compact.map(&:first_name)}"

  cols = row[2..3] + row[7..-1]
  questions.each do |question|
    question.read_response(student, rated_students, cols)
  end
end

course.teams.each do |team|
  outfile = "/tmp/#{team.section} #{team.name}.html"
  render_haml('results', outfile, title: "Midterm Team Self-Assessment", team: team, questions: questions)
  `open "#{outfile}"`
end
