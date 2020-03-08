
(require 'asdf)
; load package for .csv and .tsv parsing
(load "/home/qkation/Documents/LispFunctionalProgramming/3-lab/cl-simple-table-master/cl-simple-table.asd")
(asdf:load-system 'cl-simple-table)
; load package for .json parsing
(load "/home/qkation/Documents/LispFunctionalProgramming/3-lab/cl-json_0.5.0/cl-json.asd")
(asdf:load-system 'cl-json)

; load parse files and save data to variables
(defvar map_zal (simple-table:read-csv #P"map_zal-skl9.csv" t))
(defvar mp_assistants (simple-table:read-csv #P"mp-assistants.csv" t))
(defvar mp_posts (simple-table:read-csv #P"mp-posts_full.csv"))
(defvar plenary_register_mps (simple-table:read-tsv #P"plenary_register_mps-skl9.tsv"))
(defvar mps_declarations_rada(json:decode-json (open "./mps-declarations_rada.json")))

(defun generateSequence(n)(cond ((< n 1) '())
                                ((= n 1) '(1))
                                (t (append
                                     (generateSequence (- n 1))
                                     (list n)))
                                ))

(defun makeIndexes(i row hashTable)
  (cond ((< i 0) hashTable)
		(t (setf (gethash (aref row i) hashTable) (list (+ i 1)))
		   (makeIndexes (- i 1) row hashTable)
		  )
		)
  )

(defun makeHashMap(row)
  (setf tmpHashTable (make-hash-table))
  (setf (gethash '* tmpHashTable) (generateSequence (array-total-size row)))
  (makeIndexes (- (array-total-size row) 1) row tmpHashTable)
  )

#|| test makeHashMap function
(defvar nht (makeHashMap #(A B C D E)))
(write (gethash 'A nht))
(write (gethash 'B nht))
(write (gethash 'C nht))
(write (gethash 'D nht))
(write (gethash 'E nht))
(write (gethash '* nht))
(exit)
||#

(defun split-str-1 (string &optional (separator " ") (r nil))
  (let ((n (position separator string
                   :from-end t
                   :test #'(lambda (x y)
                             (find y x :test #'string=)))))
    (if n
      (split-str-1 (subseq string 0 n) separator (cons (subseq string (1+ n)) r))
      (cons string r))))

(defun split-str (string &optional (separator " "))
  (split-str-1 string separator))

(defun getTableName(tokens)
  (nth 1 (member "FROM" tokens :test #'string=))
  )

#||
(write (getTable '("SELECT" "*" "FROM" "TABLE1")))
(terpri)
(write (getTable '("SELECT" "*" "FROM" "King")))
(exit)
||#

(defun getColumnsNames(tokens)
  (subseq tokens 1 (position "FROM" tokens :test #'string=))
  )

#||
(write (getColumnsNames '("SELECT" "*" "FROM" "table1")))
(terpri)
(write (getColumnsNames '("SELECT" "cal1" "cal2" "cal3" "FROM" "table3")))
(exit)
||#

(defun query(tokens)
  (setf tableName (getTableName tokens))
  (setf resultColumns ())
  resultColumns
  )

(defun printTable(simple_table row)(cond
								 ((= row 0) (pprint (simple-table:get-row 0 simple_table)))
							     (t (printTable simple_table (- row 1))
									(pprint (simple-table:get-row row simple_table)))
								 )
)
(defun printAll(tableName)(cond
							((string= tableName "map_zal-skl9")
							 (printTable map_zal (- (simple-table:num-rows map_zal) 1)))
							((string= tableName "mp-assistants")
							 (printTable mp_assistants (- (simple-table:num-rows mp_assistants) 1)))
							((string= tableName "mp-posts_full")
							 (printTable mp_posts (- (simple-table:num-rows mp_posts) 1)))
							((string= tableName "plenary_register_mps-skl9")
							 (printTable plenary_register_mps (- (simple-table:num-rows plenary_register_mps) 1)))
							((string= tableName "mps-declarations_rada")
							 (printTable mps_declarations_rada (- (simple-table:num-rows mps_declarations_rada) 1)))
							(t (princ (concatenate 'string "table not found: " tableName)))
						  )
)

(defun cutName(command)(cond ((not (position #\( command)) command)
							 (t (subseq command 0 (position #\( command)))
					   )
)
(defun cutParameter(command)(subseq command (+ (position #\( command) 1) (position #\) command)))

(defun execute(command)(cond ((string= (cutName command) "exit") "EXIT")
							 ((string= (cutName command) "load")
							   (printAll (cutParameter command)))
							 (t (princ "command not found!"))
					   )
)

(defun run ()
    (loop
        (terpri)
        (princ "[user@host ~]$: ")
		(terpri)
		(if (string= (execute (read-line)) "EXIT")
		  (return)
		  ()
		  )
    )
)

(run)
