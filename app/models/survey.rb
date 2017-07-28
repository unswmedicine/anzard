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

class Survey < ApplicationRecord
  has_many :responses, dependent: :destroy
  has_many :sections, -> {order(:section_order)}, dependent: :destroy
  has_many :questions, through: :sections

  scope :by_name, -> {order(:name)}

  validates :name, presence: true, uniqueness: {case_sensitive: false}

  def ordered_questions
    # retrieve by iterating over sections rather than using has_many questions through, so that we can use our preloaded survey data instead of doing db queries
    all_questions.sort_by { |q| [q.section.section_order, q.question_order] }
  end

  def first_section
    sections.first
  end

  def section_with_id(section_id)
    sections.find{ |s| s.id == section_id.to_i}
  end

  def mandatory_question_ids
    # retrieve by iterating over sections rather than using has_many questions through, so that we can use our preloaded survey data instead of doing db queries
    all_questions.select {|q| q.mandatory }.collect(&:id)
  end

  # find the next section after the section with the given id
  def section_id_after(section_id)
    section_ids = sections.collect(&:id)
    current_index = section_ids.index(section_id)
    raise "Didn't find any section with id #{section_id} in this survey" unless current_index
    raise "Tried to call section_id_after on last section" if current_index == (section_ids.size - 1)
    section_ids[current_index + 1]
  end

  def destroy
    # This is here as a safety measure, if we implement delete, it will need to be removed.
    if Rails.env.development? or Rails.env.test?
      super
    else
      raise "Can't destroy surveys in production! \n" +
                "Destroying a survey would destroy *all* of the questions and answers that have been associated with it."
    end
  end

  def question_with_code(code)
    return nil if code.blank?
    populate_question_hash if @question_map.nil?
    @question_map[code.downcase]
  end

  private

  def all_questions
    # retrieve by iterating over sections rather than using has_many questions through, so that we can use our preloaded
    # survey data instead of doing db queries
    sections.collect(&:questions).flatten
  end

  def populate_question_hash
    # optimisation used by batch processing - load all the questions once and store them in a hash keyed by question code
    @question_map = {}
    all_questions.each do |question|
      @question_map[question.code.downcase] = question
    end
  end
end