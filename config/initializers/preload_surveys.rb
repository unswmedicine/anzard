# ANZARD - Australian & New Zealand Assisted Reproduction Database
# Copyright (C) 2017 Intersect Australia Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

#This file is still used before the rails cache store memory_store get improved on marshaling speed
SURVEYS = {}
QUESTIONS = {}

class StaticModelPreloader
  def self.load
    SURVEYS.clear
    Survey.includes(sections: [questions: [:cross_question_validations, :question_options]]).order(:name).all.each do |survey|
      SURVEYS[survey.id] = survey
    end

    QUESTIONS.clear
    Question.includes(:cross_question_validations, :question_options).all.each do |question|
      QUESTIONS[question.id] = question
    end
  end
end

#StaticModelPreloader.load unless ENV['SKIP_PRELOAD_MODELS'] == 'skip'
Rails.configuration.to_prepare do
  StaticModelPreloader.load unless ENV['SKIP_PRELOAD_MODELS'] == 'skip'
end
#TODO Remove above anti-pattern by splitting 'Question' table