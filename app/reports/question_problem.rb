# Utility class for storing the details of a validation failure for a batch upload
class QuestionProblem

  attr_accessor :question_code
  attr_accessor :message
  attr_accessor :cycle_ids
  attr_accessor :type

  def initialize(question_code, message, type)
    self.question_code = question_code
    self.message = message
    self.type = type
    self.cycle_ids = []
  end

  def add_cycle_id(code)
    cycle_ids << code
  end

end