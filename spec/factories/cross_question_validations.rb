FactoryGirl.define do
  factory :cross_question_validation do
    association :question
    association :related_question, factory: :question
    error_message "err"
    #We are using a sequence that doesn't sequence here because there is a name collision with Rake::DSL.rule
    sequence(:rule){'comparison'}
    operator '=='
    constant 0
    set_operator nil
    set nil
    conditional_operator nil
    conditional_constant nil
    conditional_set_operator nil
    conditional_set nil
    primary true

    #Comparisons
    factory :cqv_comparison do
      sequence(:rule){'comparison'}
      operator '=='
    end

    #Implecations
    factory :cqv_date_implies_constant do
      sequence(:rule){'date_implies_constant'}
      operator "=="
      constant -1
    end

    factory :cqv_const_implies_const do
      sequence(:rule){'const_implies_const'}
      conditional_operator "!="
      conditional_constant 0
      operator ">"
      constant 0
    end

    factory :cqv_const_implies_set do
      sequence(:rule){'const_implies_set'}
      conditional_operator "!="
      conditional_constant 0
      set_operator "included"
      set [1,3,5,7]
    end

    factory :cqv_set_implies_const do
      sequence(:rule){'set_implies_const'}
      conditional_set_operator "included"
      conditional_set [2,4,6,8]
      operator ">"
      constant 0
    end

    factory :cqv_set_implies_set do
      sequence(:rule){'set_implies_set'}
      conditional_set_operator "included"
      conditional_set [2,4,6,8]
      set_operator "included"
      set [1,3,5,7]
    end

    factory :cqv_blank_unless_const do
      sequence(:rule){'blank_unless_const'}
      conditional_operator "=="
      conditional_constant -1
    end

    factory :cqv_blank_unless_set do
      sequence(:rule){'blank_unless_set'}
      conditional_set_operator "range"
      conditional_set [0,99]
    end

  end
end
