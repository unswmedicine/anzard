## Overview

In order to populate the ANZARD System with questions, the following three files should be provided (assuming a data entry form named "Main"):

* main_questions.csv
* main_question_options.csv
* main_cross_question_validations.csv

While the exact naming of the files is currently not important, they should follow this convention so that - should the insertion process become automated in the future - they remain compatible

Each file is a 'normal' csv file and can be generated without issue from Excel or other similar tools. From Excel, simply use the "Save As.." option and choose Comma Separated Values (.csv) as the file type.

Unicode characters such as (but not limited to) smart quotes (‘—’ and “—”) and bullets (•) will confuse the CSV parser. To save a lot of pain, turn them off if your CSV editor uses them (Excel). A list of common troublesome unicode characters can be seen [here](developer/illegal_characters.txt)

## Content


### main_questions.csv

This file contains all of the questions, one question per row. Heading order is not critical.

 Heading | Format | Required? | Content 
---|---|---|---
section | Text | Y | The title of the section this should appear in. Sections are created automatically based on this field. Sections are ordered based on their first appearance in this spreadsheet, so try to group questions in the order that you would like them to appear 
 question_order | Integer | Y | The order within a section that this question will appear. Must be unique within the section. 
 code | Text | Y | The question code from the ANZARD Data Dictionary 
 question | Text | Y | The question text&nbsp;from the ANZARD Data Dictionary 
 question_type | Text | Y | Question type. Must be one of the following and is case-sensitive:&nbsp;Integer, Decimal, Date, Time, Choice, Text 
 mandatory | Boolean | Y | Question is mandatory for submission. Must be TRUE or FALSE 
multiple | Boolean | N | Question is part of a collection of related questions (eg Surgeries)
multi_name | String | If multiple is true | The name of the collection
group_number | Integer | If multiple is true | The group within the collection. Take care with this field, ideally see an example in the sample data
order_within_group | Integer | If multiple is true | The order within a group that this question will appear. Must be unique within the group. question_order must still be correctly specified. Take care with this field, ideally see an example in the sample data 
 number_min | Decimal/Integer | Integer/Decimal Qns Only | The minimum value (inclusive) allowed for this question without raising a warning 
 number_max | Decimal/Integer |  Integer/Decimal Qns Only | The maximum value (inclusive) allowed for this question without raising a warning 
 number_unknown | Decimal/Integer |  Integer/Decimal Qns Only - only fill in if you want to allow a special value for unknown | An alternate value used if the answer is unknown 
 string_min | Integer |String Qns Only | The shortest length (Inclusive) allowed for an answer to a text-type question 
 string_max | Integer | String Qns Only | The longest length (Inclusive) allowed for an answer to a text-type question
 guide_for_use | Text | N | The guide for use&nbsp;from the ANZARD Data Dictionary 
 description | Text | N | The question description&nbsp;from the ANZARD Data Dictionary 

### main_question_options.csv

This file contains the options for choice-type questions. One option per row.

 Heading | Format | Required? | Content 
---|---|---|---
 code | Text | Y | The question code that this option relates to. This must exactly match the code field in my_survey_questions.csv 
 option_value | Text/Decimal/Integer | Y | The value that is stored by selecting this option 
 label | Text | Y | The text displayed for this option 
 hint_text | Text | N | Additional information for this option (from ANZARD data dictionary). See sample files for examples 
 option_order | Decimal | Y | The order within a question that these options will appear. Must be unique within the question 

### main_cross_question_validations.csv

This file contains the validation rules for questions that are dependent on the value of another question. 
See [Cross Question Validations](cross_question_validations.md)