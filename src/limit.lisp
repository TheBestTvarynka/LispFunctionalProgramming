
(defun limit (limitStr table)
  (let ((n (parse-integer (string-trim " " limitStr)))
		(len (table-len table)))
    (make-table :tableName (table-tableName table)
                :columnNames (table-columnNames table)
                :columnIndexes (table-columnIndexes table)
                :data (subseq (table-data table) 0 (cond ((> n len) len)(t n))))
	)
  )