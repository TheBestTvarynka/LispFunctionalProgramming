(require 'asdf)
(load "cl-simple-table-master/cl-simple-table.asd")
(asdf:load-system 'cl-simple-table)
; maybe instead of functions from this package I will write my own function

(load "distinct.lisp")
(load "stack/stack.lisp")
(load "functions.lisp")
(load "importer.lisp")

(defun generateColumn (len val)
  (make-array len :initial-element val)
  )

(defun generateValue (value table)
  (let ((col (generateColumn (table-len table) value)))
	(lambda ()
	  (make-table :columnNames "?column?" :data col)
	  )
	)
  )

(defun selectCoumn (index data)
  (reduce (lambda (column row)
			(vector-push-extend (aref row index) column)
			column
			)
		  data
		  :initial-value (make-array 0 :fill-pointer 0))
  )

(defun generateColumnValue (colname table)
  ;(pprint colname)
  ;(pprint table)
  (let ((colIndex (nth 0 (gethash colname (table-columnIndexes table)))))
    (let ((col (selectCoumn colIndex (table-data table))))
	  (lambda ()
	    (make-table :columnNames colname :data col)
	    )
	  )
	)
  )

(defun appendValue (lst value)
  (append lst (list value))
  )

(defun generateFunction (fnname args)
  (let ((fn (getFunction fnname)))
	(lambda ()
	  (apply fn args)
	  )
	)
  )

(defun ifOperator (ch)
  (cond
	((or (char= #\+ ch)
		 (char= #\- ch)
		 (char= #\* ch)
		 (char= #\/ ch)
		 (char= #\( ch)
		 (char= #\) ch)
		 (char= #\, ch)) t)
	(t nil)
	)
  )

(defun getOperatorPriority (fn)
  (cond
	((string= fn "=") 10)
	((or (string= fn "*")
		 (string= fn "/")) 8)
	((or (string= fn "+")
		 (string= fn "-")) 7)
	((string= fn "(") 6)
	(t 9)
	)
  )

(defun insertClosingBracket (operators stack)
  (let ((topOperator (stack-top stack)))
	(cond
	  ((string= topOperator "(")
	   (stack-pop stack)
	   operators)
	  (t (insertClosingBracket (appendValue operators topOperator) (stack-pop stack)))
	  )
	)
  )

(defun insertComa (operators stack)
  (let ((topOperator (stack-top stack)))
	(cond
	  ((stack-is-empty stack) (appendValue operators ","))
	  ((string= topOperator "(") operators)
	  (t (insertComa (appendValue operators topOperator) (stack-pop stack)))
	  )
	)
  )

(defun insertOperator (operator operators stack)
  (let ((topOperator (stack-top stack)))
	(cond
	  ((string= operator "(")
	   (stack-push operator stack)
	   operators)
	  ((stack-is-empty stack)
	   (stack-push operator stack)
	   operators)
	  ((>= (getOperatorPriority topOperator) (getOperatorPriority operator))
	   (insertOperator operator (appendValue operators topOperator) (stack-pop stack)))
	  (t (stack-push operator stack)
		 operators)
	  )
	)
  )

(defun insertOperatorInStack (operator operators stack)
  (let ((topOperator (stack-top stack)))
	(cond
	  ((string= operator ")") (insertClosingBracket operators stack))
	  ((string= operator ",") (insertComa operators stack))
	  (t (insertOperator operator operators stack))
	  )
	)
  )

(defun clearStack (operators stack)
  (cond
	((stack-is-empty stack)
	 operators)
	(t (clearStack (appendValue operators (stack-top stack)) (stack-pop stack)))
	)
  )

(defun ifNameChar (ch)
  (setf ch (char-int ch))
  (cond
	((or (and (>= ch 48) (<= ch 57))
		 (and (>= ch 65) (<= ch 90))
		 (and (>= ch 97) (<= ch 122))
		 (= ch 95)) t)
	(t nil)
	)
  )

(defun readName (selectStr operators stack table)
  (let ((nameEnd (position-if-not #'ifNameChar selectStr)))
	(cond
	  ((not nameEnd)
	   (setf operators (appendValue operators (generateColumnValue selectStr table)))
	   (parseSelect "" operators stack table))
	  ((char= #\( (char selectStr nameEnd))
	   (let ((funName (subseq selectStr 0 nameEnd)))
	      (setf operators (insertOperatorInStack funName operators stack))
	      (setf selectStr (string-left-trim " " (subseq selectStr nameEnd)))
	      (parseSelect selectStr operators stack table)
		  ))
	  (t (setf operators (appendValue operators (generateColumnValue (subseq selectStr 0 nameEnd) table)))
		 (setf selectStr (string-left-trim " " (subseq selectStr nameEnd)))
		 (parseSelect selectStr operators stack table))
	  )
	)
  )

(defun readStringValue (selectStr operators stack table)
   (let ((value (subseq selectStr 1 (position #\' selectStr :start 1))))
	 (setf selectStr (string-left-trim " " (subseq selectStr (+ (length value) 2))))
	 (setf operators (appendValue operators (generateValue value table)))
	 (parseSelect selectStr operators stack table)
	 )
  )

(defun readIntValue (selectStr operators stack table)
  (let ((value (subseq selectStr 0 (position-if-not #'digit-char-p selectStr))))
	(setf selectStr (string-left-trim " " (subseq selectStr (length value))))
	(setf operators (appendValue operators (generateValue (read-from-string value) table)))
	(parseSelect selectStr operators stack table)
	)
  )

(defun readOperator (selectStr operators stack table)
  (let ((ch (subseq selectStr 0 1)))
    (setf selectStr (string-left-trim " " (subseq selectStr 1)))
    (parseSelect selectStr (insertOperatorInStack ch operators stack) stack table)
	)
  )

(defun parseSelect (selectStr operators stack table)
  (cond
	((string= selectStr "")
     (clearStack operators stack))
	(t
      (let ((ch (char selectStr 0)))
        (cond
  	      ((digit-char-p ch)
		   (readIntValue selectStr operators stack table))
  	      ((char= #\' ch)
		   (readStringValue selectStr operators stack table))
          ((ifOperator ch)
		   (readOperator selectStr operators stack table))
	      ((ifNameChar ch)
		   (readName selectStr operators stack table))
	      (t nil)
  	      )
		)
	  )
	)
  )

(defun removeLast (lst n)
  (remove-if (constantly t) lst :count n :from-end t)
  )

(defun buildFunctions (prevOperators nextOperators)
  (let ((next (car nextOperators)))
	(cond
	  ((not nextOperators) prevOperators)
	  ((functionp next)
	   (buildFunctions (appendValue prevOperators next) (cdr nextOperators)))
	  ((stringp next)
	   (cond
		 ((string= next ",")
		  (buildFunctions prevOperators (cdr nextOperators)))
		 (t (let ((paramAmount (getArgumentAmount next)))
			  (buildFunctions (appendValue (removeLast prevOperators paramAmount)
										   (generateFunction next (last prevOperators paramAmount)))
							  (cdr nextOperators))
			  ))
		 ))
	  (t (pprint "DEFAULT CASE")
		 nil)
	  )
	)
  )

(defun select (selectStr table)
  ;(pprint "in select")
  ;(pprint selectStr)
  (setf selectStr (string-left-trim " " selectStr))
  (let ((fns (buildFunctions '() (parseSelect selectStr '() (make-stack) table))))
	(let ((columns (mapcar (lambda (colFn)(funcall colFn)) fns)))
	  (make-table :tableName (table-tableName table)
				  :columnNames (make-array (length columns)
										   :initial-contents (mapcar (lambda (col)
																	   (table-columnNames col)
																	   )
																	 columns))
				  :data (iterate (lambda (&rest row)
								   (make-array (length row) :initial-contents row)
								   )
								 (make-array 0 :fill-pointer 0)
			    				 0
			   					 (table-len (nth 0 columns))
			   					 (mapcar (lambda (col)(table-data col)) columns)))
	  )
	)
  )

;(defvar simple (make-table :tableName "test"
						   ;:columnNames '("col1" "col2" "col3")
						   ;:columnIndexes (makeIndexHashMap #("col1" "col2" "col3"))
						   ;:data #(#(1 "pasha programmer" 61)
								   ;#(2 "pacha uzurpator" 98)
								   ;#(3 "asan homeless" 645)
								   ;#(4 "yter king" 5)
								   ;#(5 "Q'Kation" 15)
								   ;)))

;(test "col3")
;(pprint (select "col1 + 1, col2" simple))
;(test "concat('name is: ', col2)")
;(test "concat('piece: ', substr(col2, col1, 2))")
;(pprint "========================")
;(test "col1 + 1, concat('name is: ', col2)")
#||
(pprint (parseSelect "1 + 3*(fn('value', id, 3) +2) - 4" '() (make-stack) nil))
(pprint (parseSelect "1 + 3*(fn('value', 43 + id * 6, 3) +2) - 4" '() (make-stack) nil))
(pprint (parseSelect "1 + 3*(fn('value', 43 + count(id) * 6, 3) +2) - 4" '() (make-stack) nil))
(pprint (parseSelect "concat(name, ' ', description)" '() (make-stack) nil))
(pprint (parseSelect "col1" '() (make-stack) nil))
(pprint (parseSelect "2 +id" '() (make-stack) nil))
(pprint (parseSelect "col1, 2 + id, concat('name is: ', name)" '() (make-stack) nil))
(pprint (parseSelect "3+6*5, pow(2 + id, 2) + 3, concat('name is: ', name)" '() (make-stack) nil))
;||#

