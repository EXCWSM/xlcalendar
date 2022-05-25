;;; -*- Mode: Lisp;  Package: EDITOR; -*-
;;; This file is not part of xyzzy.
;;;
;;; Large calendar for xyzzy
;;;
;;; usage:
;;;   (require "howm-wrap") ;; Hitori Otegaru Wiki Modoki http://howm.osdn.jp/
;;;   (require "lcalendar")
;;;   M-x lc [RET][RET]

(provide "lcalendar")

(in-package "editor")

(export '(lcalendar
	  *lcalendar-mode-map*
	  *lcalendar-faces*
	  *lcalendar-show-schedule*
	  *lcalendar-func-schedules*
	  *lcalendar-func-visit-schedule*
	  *lcalendar-func-new-schedule*
	  *lcalendar-header-date-format*
	  *lcalendar-weekday-names*
	  *lcalendar-func-holiday*
	  ))

(defvar *lcalendar-mode-map* nil)
(unless *lcalendar-mode-map*
  (setf *lcalendar-mode-map* (make-sparse-keymap))
  (define-key *lcalendar-mode-map* #\b 'lcalendar-previous-day)
  (define-key *lcalendar-mode-map* #\c 'lcalendar-new-schedule)
  (define-key *lcalendar-mode-map* #\f 'lcalendar-next-day)
  (define-key *lcalendar-mode-map* #\g 'lcalendar-refresh)
  (define-key *lcalendar-mode-map* #\M-g 'lcalendar-goto-date)
  (define-key *lcalendar-mode-map* #\n 'lcalendar-next-week)
  (define-key *lcalendar-mode-map* #\p 'lcalendar-previous-week)
  (define-key *lcalendar-mode-map* #\q 'kill-selected-buffer)
  (define-key *lcalendar-mode-map* #\T 'lcalendar-toggle-schedule)
  (define-key *lcalendar-mode-map* #\C-v 'lcalendar-next-month)
  (define-key *lcalendar-mode-map* #\M-v 'lcalendar-previous-month)
  (define-key *lcalendar-mode-map* '(#\C-x #\]) 'lcalendar-next-year)
  (define-key *lcalendar-mode-map* '(#\C-x #\[) 'lcalendar-previous-year)
  (define-key *lcalendar-mode-map* #\M-} 'lcalendar-next-month)
  (define-key *lcalendar-mode-map* #\M-{ 'lcalendar-previous-month)
  (define-key *lcalendar-mode-map* #\. 'lcalendar-goto-today)
  (define-key *lcalendar-mode-map* #\> 'lcalendar-next-month)
  (define-key *lcalendar-mode-map* #\< 'lcalendar-previous-month)
  (define-key *lcalendar-mode-map* #\PageDown 'lcalendar-next-month)
  (define-key *lcalendar-mode-map* #\PageUp 'lcalendar-previous-month)
  (define-key *lcalendar-mode-map* #\RET 'lcalendar-visit-schedule)
  )

(defvar *lcalendar-faces*
  '((sun . (:foreground 1))
    (sat . (:foreground 4))
    (holiday . (:foreground 1))
    (today . (:underline t))
    (header-sun . (:foreground 1))
    (header-sat . (:foreground 4))
    ))

(defvar *lcalendar-show-schedule* t)

(defvar *lcalendar-func-schedules*
  'lcalendar-howm-schedules
  "(SCHEDULE-FUNCTION year month) ===> '((YEAR MONTH DAY \"CAPTION\") ...)")

(defvar *lcalendar-func-visit-schedule*
  'lcalendar-howm-visit
  "(SCHEDULE-VISIT year month day)")

(defvar *lcalendar-func-new-schedule*
  'lcalendar-howm-new
  "(SCHEDULE-NEW year month day)")

(defvar *lcalendar-header-date-format*
  "%YîN %måé")

(defvar *lcalendar-weekday-names*
  '("ì˙" "åé" "âŒ" "êÖ" "ñÿ" "ã‡" "ìy"))

(defvar *lcalendar-func-holiday*
  (if (fboundp 'ed::calendar-japanese-holiday)
      'ed::calendar-japanese-holiday)
  "(HOLIDAY-FUNCION year month holiday-vector)")

(defun lcalendar (&optional year month day)
  (interactive)
  (set-buffer (setq buf (get-buffer-create "*Large Calendar*")))
  (kill-all-local-variables)
  (setup-temp-buffer (selected-buffer))
  (make-local-variable 'buffer-mode)
  (setq buffer-mode 'lcalendar-mode)
  (make-local-variable 'mode-name)
  (setq mode-name "lcalendar")
  (make-local-variable 'lcalendar-current-year)
  (make-local-variable 'lcalendar-current-month)
  (use-keymap *lcalendar-mode-map*)
  (erase-buffer (selected-buffer))
  (let ((now (multiple-value-list (get-decoded-time))))
    (lcalendar-write (or year (nth 5 now))
		     (or month (nth 4 now))
		     (if (or (not (and year month))
			     (and (numberp year) (= year (nth 5 now))
				  (numberp month) (= month (nth 4 now))))
			 (nth 3 now))
		     *lcalendar-show-schedule*)
    (lcalendar-goto-day (or day
			    (if (or (not (and year month))
				    (and (numberp year) (= year (nth 5 now))
					 (numberp month) (= month (nth 4 now))))
				(nth 3 now))
			    1)))
  (run-hooks '*lcalendar-mode-hook*)
  (set-buffer-modified-p nil)
  (setq buffer-read-only t))

(defun lcalendar-write (year month today show-schedule)
  (unless (numberp today)
    (setq today -1))
  (let* ((startIndex (ed::calendar-ut-day year month 1))
	 (lastday (ed::calendar-gregorian-last-day-of-month year month))
	 (calRows (ceiling (+ startIndex lastday) 7))
	 (cellRows (max (ceiling (- (window-lines) 2) (1+ calRows)) 3))
	 (cellCols (max (1+ (ceiling (window-columns) 8)) 12))
	 (cellFormat (format nil "~~~D@A|" cellCols))
	 (sepline
	  (let ((result))
	    (map nil
		 #'(lambda (x) (setq result (concat result x)))
		 (make-list 7 :initial-element (concat (make-sequence 'string cellCols :initial-element #\-) "+")))
	    result))
	 (holidays (make-vector 33))
	 (schedules (make-hash-table :test #'equal :size 509))
	 (old-point (point)))
    (setq lcalendar-current-year year)
    (setq lcalendar-current-month month)
    (if (fboundp *lcalendar-func-holiday*)
	(funcall *lcalendar-func-holiday* year month holidays))
    (if (and show-schedule
	     (fboundp *lcalendar-func-schedules*))
	(let ((oldday 0) (schidx 0))
	  (map nil
	       #'(lambda (item)
		   (when (/= oldday (nth 2 item))
		     (setq oldday (nth 2 item))
		     (setq schidx 0))
		   (setf (gethash (+ (* (nth 2 item) 100) schidx) schedules) (nth 3 item))
		   (setq schidx (1+ schidx)))
	       (funcall *lcalendar-func-schedules* year month))))
    ;; header
    (insert (format-date-string *lcalendar-header-date-format* (encode-universal-time 0 0 0 1 month year)) "\n")
    (dotimes (i 7)
      (let ((p1 (point))
	    (weekname (nth i *lcalendar-weekday-names*)))
	(insert (format nil cellFormat weekname))
	(cond ((= i 0)
	       (apply 'set-text-attribute p1 (+ p1 (length weekname)) 'lcalender-header (cdr (assoc 'header-sun *lcalendar-faces*))))
	      ((= i 6)
	       (apply 'set-text-attribute p1 (+ p1 (length weekname)) 'lcalender-header (cdr (assoc 'header-sun *lcalendar-faces*)))))))
    (insert "\n" sepline "\n")
    ;; details
    (let ((cellIndex 0) (day 0)
	  (face-sun (cdr (assoc 'sun *lcalendar-faces*)))
	  (face-sat (cdr (assoc 'sat *lcalendar-faces*)))
	  (face-holiday (cdr (assoc 'holiday *lcalendar-faces*)))
	  (face-today (cdr (assoc 'today *lcalendar-faces*))))
      (dotimes (i calRows)
	(if (and (<= 1 i) (< lastday day))
	    (return nil))
	(let ((sunday (if (< 0 day) day (- 0 startIndex))))
	  (dotimes (j 7)
	    (if (<= startIndex cellIndex)
		(setq day (1+ day)))
	    (setq cellIndex (1+ cellIndex))
	    (if (or (= day 0) (< lastday day))
		(insert (format nil cellFormat ""))
	      (let ((p1 (point)) (holiday (svref holidays day)))
		(setq holiday (if (stringp holiday) holiday nil))
		(insert (format nil cellFormat (lcalendar-truncate-string (concat (format nil "~D" day) " " holiday) cellCols)))
		(apply 'set-text-attribute
		       p1
		       (+ p1 2)
		       'lcalendar
		       (append (cond (holiday face-holiday)
				     ((= j 0) face-sun)
				     ((= j 6) face-sat))
			       (if (= today day) face-today)))
		)))
	  (insert "\n")
	  (dotimes (j (1- cellRows))
	    (dotimes (k 7)
		(insert (format nil cellFormat (lcalendar-truncate-string (gethash (+ (* (+ sunday k 1) 100) j) schedules "") cellCols))))
	    (insert "\n"))
	  (insert sepline "\n")
	  )
	)
      )
    (goto-char old-point)))

(defun lcalendar-refresh ()
  (interactive)
  (lcalendar lcalendar-current-year lcalendar-current-month (lcalendar-day-at-cursor)))

(defun lcalendar-day-at-cursor (&optional default-result)
  (or
   (save-excursion
     (let ((c1 (current-column)))
       (dolist (x (reverse (list-text-attributes (point-min) (1+ (point)))))
	 (if (and (eq (nth 2 x) 'lcalendar)
		  (<= (progn (goto-char (nth 0 x)) (current-column)) c1))
	     (let ((day (parse-integer (buffer-substring (nth 0 x) (nth 1 x)) :junk-allowed t)))
	       (if (numberp day)
		   (return day)))))))
   default-result))

(defun lcalendar-goto-day (day)
  (setq day (cond ((not (numberp day))
		   1)
		  ((< day 1)
		   1)
		  (t
		   (min day
			(ed::calendar-gregorian-last-day-of-month lcalendar-current-year lcalendar-current-month)))))
  (let ((c1 (current-column)))
    (dolist (x (list-text-attributes))
      (when (eq (nth 2 x) 'lcalendar)
	(let ((d (parse-integer (buffer-substring (nth 0 x) (nth 1 x)) :junk-allowed t)))
	  (when (= day d)
	    (goto-char (nth 0 x))
	    (return t)))))))

(defun lcalendar-next-day ()
  (interactive)
  (let ((day (1+ (lcalendar-day-at-cursor 0))))
    (if (< (ed::calendar-gregorian-last-day-of-month lcalendar-current-year lcalendar-current-month) day)
	(lcalendar-next-month 1)
      (lcalendar-goto-day day))))

(defun lcalendar-previous-day ()
  (interactive)
  (let ((day (1- (lcalendar-day-at-cursor 2))))
    (if (< day 1)
	(lcalendar-previous-month 32)
      (lcalendar-goto-day day))))

(defun lcalendar-next-week ()
  (interactive)
  (let ((day (+ 7 (lcalendar-day-at-cursor 1)))
	(lastday (ed::calendar-gregorian-last-day-of-month lcalendar-current-year lcalendar-current-month)))
    (if (< lastday day)
	(lcalendar-next-month (- day lastday))
      (lcalendar-goto-day day))))

(defun lcalendar-previous-week ()
  (interactive)
  (let ((day (- (lcalendar-day-at-cursor (ed::calendar-gregorian-last-day-of-month lcalendar-current-year lcalendar-current-month))
		7)))
    (if (< day 1)
	(lcalendar-previous-month day)
      (lcalendar-goto-day day))))

(defun lcalendar-next-month (&optional day)
  (interactive)
  (let ((year lcalendar-current-year)
	(month lcalendar-current-month))
    (if (= 12 month)
	(setq year (1+ year)
	      month 1)
      (setq month (1+ month)))
    (lcalendar year month (or day (lcalendar-day-at-cursor)))))

(defun lcalendar-previous-month (&optional day)
  (interactive)
  (let ((year lcalendar-current-year)
	(month lcalendar-current-month))
    (if (= 1 month)
	(setq year (1- year)
	      month 12)
      (setq month (1- month)))
    (if (< (or day 1) 1)
	(setq day (+ (ed::calendar-gregorian-last-day-of-month year month) day)))
    (lcalendar year month (or day (lcalendar-day-at-cursor)))))

(defun lcalendar-next-year (&optional day)
  (interactive)
  (lcalendar (1+ lcalendar-current-year)
	     lcalendar-current-month
	     (or day (lcalendar-day-at-cursor))))

(defun lcalendar-previous-year (&optional day)
  (interactive)
  (lcalendar (1- lcalendar-current-year)
	     lcalendar-current-month
	     (or day (lcalendar-day-at-cursor))))

(defun lcalendar-goto-date (&optional (year lcalendar-current-year)
				      (month lcalendar-current-month)
				      day)
  (interactive)
  (let ((sdate (let ((now (multiple-value-list (get-decoded-time))))
		 (format nil
			 "~d ~d"
			 (or year (nth 5 now))
			 (or month (nth 4 now))))))
    (loop
      (let ((cdate (split-string (read-string "Date (yyyy mm): " :default sdate) ".-/ ")))
	(if (= 0 (list-length cdate))
	    (let ((now (multiple-value-list (get-decoded-time))))
	      (setq year (nth 5 now))
	      (setq month (nth 4 now))
	      (setq day (nth 3 now))
	      (return t))
	  (if (<= 2 (list-length cdate))
	      (handler-case
		  (progn
		    (setq year (parse-integer (nth 0 cdate)))
		    (setq month (parse-integer (nth 1 cdate)))
		    (if (stringp (nth 2 cdate))
			(setq day (parse-integer (nth 2 cdate))))
		    (return t))
		(error (c) nil))
	    (message "invalid date. please re-enter date."))))))
  (lcalendar year month (or day (lcalendar-day-at-cursor))))

(defun lcalendar-goto-today ()
  (interactive)
  (let ((now (multiple-value-list (get-decoded-time))))
    (if (and (= (nth 5 now) lcalendar-current-year)
	     (= (nth 4 now) lcalendar-current-month))
	(lcalendar-goto-day (nth 3 now))
      (lcalendar))))

(defun lcalendar-truncate-string (str width)
  (let ((result "")
	(disp 0))
    (map nil
	 #'(lambda (ch)
	     (setq width (- width (if (kanji-char-p ch) 2 1)))
	     (if (<= 0 width)
		 (setq result (concat result (string ch)))))
	 str)
    result))

(defun lcalendar-toggle-schedule ()
  (interactive)
  (setq *lcalendar-show-schedule* (not *lcalendar-show-schedule*))
  (lcalendar-refresh))

(defun lcalendar-new-schedule ()
  (interactive)
  (if (fboundp *lcalendar-func-new-schedule*)
      (let ((day (lcalendar-day-at-cursor)))
	(if (numberp day)
	    (funcall *lcalendar-func-new-schedule*
		     lcalendar-current-year
		     lcalendar-current-month
		     day)))))

(defun lcalendar-visit-schedule ()
  (interactive)
  (if (fboundp *lcalendar-func-visit-schedule*)
      (let ((day (lcalendar-day-at-cursor)))
	(if (numberp day)
	    (funcall *lcalendar-func-visit-schedule*
		     lcalendar-current-year
		     lcalendar-current-month
		     day)))))

(defun lcalendar-howm-schedules (year month)
  (sort
   (remove-if #'null
	      (mapcar
	       #'(lambda (sc)
		   (let* ((item (split-string (nth 1 sc) "[-] " nil " Å@"))
			  (item-year (parse-integer (nth 0 item)))
			  (item-month (parse-integer (nth 1 item))))
		     (if (and (= year item-year)
			      (= month item-month))
			 (list item-year
			       item-month
			       (parse-integer (nth 2 item))
			       (let ((result))
				 (map nil
				      #'(lambda (s)
					  (if (stringp s)
					      (setq result (if (stringp result) (concat result " " s) s))))
				      (cddddr item))
				 result)))))
	       (elib::howm-reminder-search elib::howm-schedule-types)))
   #'(lambda (x y)
       (let ((x-date (+ (* 10000 (nth 0 x)) (* 100 (nth 1 x)) (nth 2 x)))
	     (y-date (+ (* 10000 (nth 0 y)) (* 100 (nth 1 y)) (nth 2 y))))
	 (if (= x-date y-date)
	     (string< (nth 3 x) (nth 3 y))
	   (< x-date y-date))))))

(defun lcalendar-howm-visit (year month day)
  (elib::howm-search (format nil
			     "\\[~4,'0D-~2,'0D-~2,'0D\\]~A"
			     year
			     month
			     day
			     elib::howm-schedule-types)
		     nil))

(defun lcalendar-howm-new (year month day)
  (elib::howm-create-file)
  (elib::howm-open-today)
  (insert "=\n"
	  (elib::format-time-string elib::howm-template-date-format) "\n"
	  "\n"
	  (format nil "[~4,'0D-~2,'0D-~2,'0D]@ " year month day))
  (save-excursion
    (insert "\n")))

;; lcalendar.l ends here
