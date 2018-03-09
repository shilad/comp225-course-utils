require_relative 'env'

MAX_TEAM_SIZE = 4

class Array
  def median
    return (0/0.0) if empty?
    sorted = self.sort
    (
      sorted[length / 2] +
      sorted[(length - 1) / 2]
    ) / 2.0
  end
end

# Questionnaire model

class Question
  def initialize(title)
    @title = title
  end

  attr_reader :title

  def read_response(respondent, rated_students, cells)
    record_response(respondent, rated_students, *cells.shift(columns))
  end
end

class SingleAnswerQuestion < Question
  def initialize(*args)
    super(*args)
    @answers = {}
  end

  def columns
    1
  end

  def record_response(respondent, rated_students, answer)
    @answers[respondent] = answer
  end

  def answer_for(student)
    @answers[student]
  end
end

class SingleScale < SingleAnswerQuestion
end

class OpenAnswer < SingleAnswerQuestion
end

class PerMemberQuestion < Question
  def initialize(*args, &ratings_transform)
    super(*args)
    @ratings = {}
    @ratings_transform = ratings_transform || lambda { |x| x }
  end

  def columns
    MAX_TEAM_SIZE
  end

  def record_response(respondent, rated_students, *ratings)
    ratings = @ratings_transform.call(ratings)
    rated_students.zip(ratings).each do |rated_student, rating|
      next unless rated_student  # happens if team size < max size
      @ratings[[respondent, rated_student]] = normalize_rating(rating)
    end
  end

  def rating(student, rated_student)
    @ratings[[student, rated_student]]
  end

  def ratings_from(student)
    @ratings
      .select { |(k,v)| k == student }
      .map { |k,v| v }
  end

protected

  def normalize_rating(rating)
    rating
  end
end

class MemberOpenAnswer < PerMemberQuestion
end

class MemberScale < PerMemberQuestion
  def median_rating_from(student)
    ratings_from(student).compact.median
  end

protected

  def normalize_rating(rating)
    return nil unless rating && rating =~ /^\s*\d+\s*$/
    rating.to_i
  end

end

