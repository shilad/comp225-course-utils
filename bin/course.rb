require_relative 'env'
require 'json'

class Student
  attr_reader :first_name, :last_name, :full_name, :all_name_variants
  attr_reader :team, :email

  def initialize(row)
    @first_name = row.fetch('First name').strip
    @last_name = row.fetch('Last name').strip
    @email = row.fetch('Email')
    # @github_user = row.fetch('Github username')
    @all_name_variants = []
    variants =
      (
        [first_name, full_name, first_name_last_initial] +
        (
          (row.fetch('Name variants') || '').split(',').flat_map do |variant|
            [variant, "#{variant} #{last_name}"]
          end
        )
      )
    variants.each { |v| add_name_variant(v) }
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def first_name_last_initial
    "#{first_name} #{last_name[0]}"
  end

  def join_team(team)
    if @team
      raise "#{full_name} already belongs to #{@team.name}; cannot also join #{team.name}"
    end
    @team = team
    team.members << self
  end

  def add_name_variant(variant)
    @all_name_variants << variant.downcase.strip
  end
end

class Team
  attr_reader :name, :section, :members

  def initialize(name, section)
    @name = name
    @section = section
    @members = Set.new
  end

  def member_named(name_variant)
    name_variant = name_variant.downcase.strip
    possibilities = members.select do |s|
      s.all_name_variants.any? do |n|
        n == name_variant
      end
    end
    case possibilities.size
      when 0
        raise "No member of #{name} named #{name_variant.inspect}; " +
              "options are:\n#{members.flat_map(&:all_name_variants).join("\n")}"
      when 1
        possibilities.first
      else
        raise "Multiple members of #{name} named #{name_variant.inspect}"
    end
  end
end

class Course
  attr_reader :students

  def initialize
    @teams_by_name = {}
    @students = []
  end

  def teams
    @teams_by_name.values
  end

  def read_csv(file)
    headings = nil
    CSV.foreach(file, headers: :first_row) do |row|
      student = Student.new(row)
      student.join_team(
        team_named(
          row.fetch('Team'),
          row.fetch('Section')))
      add_student(student)
    end
  end

  def apply_spelling_corrections(corrections)
    corrections.each do |email, incorrect_names|
      Array(incorrect_names).each do |incorrect_name|
        student_with_email(email).add_name_variant(incorrect_name)
      end
    end
  end

  def team_named(team_name, section)
    team_name_normalized = team_name.downcase
    team = @teams_by_name[team_name_normalized] || begin
      @teams_by_name[team_name_normalized] = Team.new(team_name, section)
    end
    unless team.section == section
      raise "Section mismatch for #{team.name.inspect}: #{team.section} != #{section}"
    end
    team
  end

  def student_with_email(email)
    email += "@macalester.edu" unless email =~ /@/
    students.select { |s| s.email == email }.first or
      raise "No student with email #{email.inspect}"
  end

  def add_student(student)
    students << student
  end

  def print_summary
    teams.each do |team|
      puts "#{team.name}  (section #{team.section})"
      puts
      team.members.each do |student|
        puts "    #{student.full_name} (#{student.email})"
      end
      puts
    end
  end
end

def read_course
  course = Course.new
  
  course.read_csv(
    data_file("Enrollment info.csv"))
  
  course.apply_spelling_corrections(
    JSON.parse(File.read(
      data_file("name_spelling_corrections.json"))))
  
  course
end
