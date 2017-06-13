# File Layout #

Rules are specified in \<data entry form name>_cross_question_validations.csv - one per line. Questions can have multiple rules, and the rules are processed from earliest to latest (however processing order is unimportant)

A cross question validation file contains 15 columns, which can be thought of in two classes: Description columns and parameter columns. Description columns instruct the application as to which rule to run, which questions it is associated with and the error text. Parameter columns tell the rule how it should work

* Description Columns
  * itemnum 
  * comments 
  * question_code 
  * related_question_code 
  * related_question_list 
  * rule 
  * error_message 
* Parameter Columns
  * operator 
  * constant 
  * set_operator 
  * set 
  * conditional_operator 
  * conditional_constant 
  * conditional_set_operator 
  * conditional_set 

Any extra columns not listed above will be ignored by the application.


## Description Columns
All fields except related_question_code/list are mandatory. Either (but not both) of relate_question_code/list must be supplied.

Column | Description | Usage
---|---|---
itemnum |  This column is only used during import. If an error is encountered, the value in this field will be displayed for each offending row  |  A unique identifier, does not have to be numeric 
comments |  Human readable comments to aid future maintainers in understanding rules. The comments are stored in the database but never actually used  |  Free text 
question_code |  The base question that this CQV applies to  |  A question code from the data entry form (Case sensitive) 
related_question_code |  The other question that this CQV applies to (one-to-one rules only) |  A question code from the data entry form (Case sensitive) 
related_question_list |  The other questions that this CQV applies to (one-to-many rules only)  | Comma separated list of question codes (Case sensitive)
rule |  The rule to be applied  | See Rules below
error_message |  Text that is displayed to the user if validation fails  | Free text

## Parameter Columns
No parameter column is mandatory, however specific rules will require specific columns be supplied. See Rules below.

Column | Valid Data
---|---
 operator | == <= >= < > \!= (Note: only == and != are permitted for textual constants and sets)
 constant | any decimal, integer or text 
 set_operator | included, excluded, range, between (Note: only "included" and "excluded" are permitted for textual sets)
 set | list of numbers or text separated by commas and in square brackets where text is quoted, eg [1,3,5,7] or ["y","n","true","false"]
 conditional_operator | == <= >= < > \!= (Note: only == and != are permitted for textual conditional constants and conditional sets)
 conditional_constant | any decimal, integer or text 
 conditional_set_operator | included, excluded, range, between (Note: only "included" and "excluded" are permitted for textual sets)
 conditional_set | list of numbers or text separated by commas and in square brackets where text is quoted, eg [1,3,5,7] or ["y","n","true","false"]

## Cross Question Validation Rules
### Generic Rules
 Rule                             | Description                                                                                                                                                             
 ---|-----------                                                                                                                                                             
 comparison                       | Compare two answers. Related answer can optionally be offset by a numerical value stored in 'Constant' prior to comparison. This 'Constant' offset must be a decimal or integer in order to be used as an offset, textual constants are ignored                                                       
 present_implies_constant         | If related_question is answered, this answer must meet (constant_expression)                                                                                            
 const_implies_const              | If related_question meets (conditional constant expression), this answer must meet (constant expression)                                                                 
 const_implies_set                | If related_question meets (conditional constant expression), this answer must meet (set expression)                                                                     
 set_implies_set                  | If related_question meets (conditional set expression), this answer must meet (set expression)                                                                          
 blank_if_const                   | Unless related_question meets (conditional constant expression), this answer must be blank                                                                              
 blank_unless_present             | Unless this question is answered, related_question must be blank                                                                                                        
 multi_hours_date_to_date         | This rule is a 'comparison' comparing this answer with the difference (in hours) between two pairs of date/times. See below for more info                               
 multi_compare_datetime_quad      | This rule is a 'comparison' for two pairs of date/times. This rule should be applied to both the date and the time questions, See below for more info                   
 present_implies_present          | If this question is answered, this related_question must be answered                                                                                                    
 const_implies_present            | If this question meets (constant expression), related_question must be answered                                                                                         
 set_implies_present              | If this question meets (set expression), related_question must be answered                                                                                              
 set_present_implies_present      | If this question meets (conditional set expression) AND (first related_question in list) is present, (second related_question in list) must be answered                 
 const_implies_one_of_const       | If this answer meants (constant expression), then at least one of related_question_list must meet (conditional constant expression)                                     
 
 ### Specialised Rules
 Rule                             | Description                                                                                                                                                             
 ---|-----------
                                                                                                 

### Expected Columns
![Expected Columns](https://github.com/IntersectAustralia/anzard/raw/master/docs/developer/expected_columns.png)

### Operators
Operator | Description
---|---
== | Equal to
<= | Less than or equal to
\>=| Greater than or equal to
<  | Strictly less than
\> | Strictly greater than
!= | Not equal to
 
### Set Operators
Set Operator | Description
---|---
included | answer matches one of the supplied values
excluded | answer does not match any of the supplied values
range | answer lies between the first and last supplied value (inclusive)

### Expressions
Expressions take one of the following forms

Type | Form | Example | (Set_)Operator from example | Constant/Set from example
---|---|---|---|---
Comparison | (answer) (operator) (related_answer + (optional) constant) | BrthOrd <= Plurality + 1 | <= | 1
Constant Expression | (answer) (operator) (constant) | PNS == -1 | == | -1
Set Expression | (answer) (set_operator) (set) | PTL must be either 0 or -1 | included | \[-1,0]