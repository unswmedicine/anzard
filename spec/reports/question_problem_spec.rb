require 'rails_helper'

describe QuestionProblem do
  it "can have more cycle ids added to it" do
    qp = QuestionProblem.new("code", "msg", "error")
    qp.question_code.should == "code"
    qp.message.should == "msg"
    qp.type.should == "error"
    qp.cycle_ids.should be_empty
    qp.add_cycle_id("abc")
    qp.add_cycle_id("def")
    qp.cycle_ids.should eq(["abc", "def"])
  end
end