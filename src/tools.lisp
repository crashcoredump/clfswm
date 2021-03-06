;;; --------------------------------------------------------------------------
;;; CLFSWM - FullScreen Window Manager
;;;
;;; --------------------------------------------------------------------------
;;; Documentation: General tools
;;; --------------------------------------------------------------------------
;;;
;;; (C) 2005-2015 Philippe Brochard <pbrochard@common-lisp.net>
;;;
;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;;;
;;; --------------------------------------------------------------------------


(in-package :common-lisp-user)

(defpackage tools
  (:use common-lisp)
  (:export :it
	   :awhen
	   :aif
           :defconfig :*config-var-table* :configvar-value :configvar-group :config-default-value
           :config-all-groups
           :config-group->string
	   :find-in-hash
           :search-in-hash
           :view-hash-table
           :copy-hash-table
	   :nfuncall
	   :pfuncall
           :symbol-search
	   :create-symbol :create-symbol-in-package
	   :call-hook
           :add-new-hook
	   :add-hook
	   :remove-hook
	   :clear-timers
	   :add-timer
	   :at
	   :with-timer
	   :process-timers
	   :erase-timer
	   :timer-loop
	   :dbg
	   :dbgnl
	   :dbgc
           :make-rectangle
           :rectangle-x :rectangle-y :rectangle-width :rectangle-height
           :in-rectangle
           :distance
           :collect-all-symbols
	   :with-all-internal-symbols
	   :export-all-functions :export-all-variables
	   :export-all-functions-and-variables
	   :ensure-function
	   :empty-string-p
	   :find-common-string
           :command-in-path
	   :setf/=
	   :number->char
           :number->string
           :number->letter
	   :simple-type-of
	   :repeat-chars
	   :nth-insert
	   :split-string
           :substring-equal
           :string-match
           :extented-alphanumericp
	   :append-newline-space
	   :expand-newline
	   :ensure-list
	   :ensure-printable
	   :limit-length
	   :ensure-n-elems
	   :begin-with-2-spaces
	   :string-equal-p
	   :find-assoc-word
	   :print-space
	   :escape-string
	   :first-position
	   :find-free-number
	   :date-string
           :write-backtrace
	   :do-execute
	   :do-shell :fdo-shell :do-shell-output
	   :getenv
	   :uquit
	   :urun-prog
	   :ushell
	   :ush
	   :ushell-loop
	   :cldebug
	   :get-command-line-words
	   :string-to-list
	   :near-position
	   :string-to-list-multichar
	   :list-to-string
	   :list-to-string-list
	   :clean-string
	   :one-in-list
	   :exchange-one-in-list
	   :rotate-list
	   :anti-rotate-list
           :n-rotate-list
	   :append-formated-list
	   :shuffle-list
	   :parse-integer-in-list
	   :convert-to-number
	   :next-in-list :prev-in-list
	   :find-string
	   :find-all-strings
	   :subst-strings
	   :test-find-string
           :memory-usage
           :cpu-usage
           :battery-usage
           :battery-alert-string
           :start-system-poll
           :stop-system-poll
           :system-usage-poll))


(in-package :tools)


(defstruct rectangle x y width height)

(setq *random-state* (make-random-state t))




(defmacro awhen (test &body body)
  `(let ((it ,test))
     (when it
       ,@body)))

(defmacro aif (test then &optional else)
  `(let ((it ,test)) (if it ,then ,else)))


;;; Configuration variables
(defstruct configvar value group doc)

(defparameter *config-var-table* (make-hash-table :test #'equal))

(defmacro defconfig (name value group doc)
  `(progn
     (setf (gethash ',name *config-var-table*)
           (make-configvar :value ,value
                           :group (or ,group 'Miscellaneous)))
     (defparameter ,name ,value ,doc)))

(defun config-default-value (var)
  (let ((config (gethash var *config-var-table*)))
    (when config
      (configvar-value config))))

(defun config-group->string (group)
  (format nil "~:(~A group~)" (substitute #\Space #\- (string group))))


;;; Configuration variables
(defun config-all-groups ()
  (let (all-groups)
    (maphash (lambda (key val)
               (declare (ignore key))
               (pushnew (configvar-group val) all-groups :test #'equal))
             *config-var-table*)
    (sort all-groups (lambda (x y)
                       (string< (string x) (string y))))))




(defun find-in-hash (val hashtable &optional (test #'equal))
  "Return the key associated to val in the hashtable"
  (maphash #'(lambda (k v)
	       (when (and (consp v) (funcall test (first v) val))
		 (return-from find-in-hash (values k v))))
	   hashtable))

(defun search-in-hash (val hashtable)
  "Return the key who match the val in the hashtable"
  (let ((val (symbol-name val)))
    (maphash #'(lambda (k v)
                 (when (and (consp v) (substring-equal (symbol-name (first v)) val))
                   (return-from search-in-hash (values k v))))
             hashtable)))


(defun view-hash-table (title hashtable)
  (maphash (lambda (k v)
             (format t "[~A] ~A ~A~%" title k v))
           hashtable))

(defun copy-hash-table (hashtable)
  (let ((rethash (make-hash-table :test (hash-table-test hashtable))))
    (maphash (lambda (k v)
               (setf (gethash k rethash) v))
             hashtable)
    rethash))


(defun nfuncall (function)
  (when function
    (funcall function)))

(defun pfuncall (function &rest args)
  (when (and function
	     (or (functionp function)
		 (and (symbolp function) (fboundp function))))
    (apply function args)))



(defun symbol-search (search symbol)
  "Search the string 'search' in the symbol name of 'symbol'"
  (search search (symbol-name symbol) :test #'string-equal))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun mkstr (&rest args)
    (with-output-to-string (s)
      (dolist (a args)
	(princ a s))))

  (defun create-symbol (&rest args)
    (values (intern (string-upcase (apply #'mkstr args)))))

  (defun create-symbol-in-package (package &rest args)
    (values (intern (string-upcase (apply #'mkstr args)) package))))


;;;,-----
;;;| Minimal hook
;;;`-----
(defun call-hook (hook &rest args)
  "Call a hook (a function, a symbol or a list of functions)
Return the result of the last hook"
  (let ((result nil))
    (labels ((rec (hook)
	       (when hook
		 (typecase hook
		   (cons (dolist (h hook)
			   (rec h)))
                   (function (setf result (apply hook args)))
		   (symbol (when (fboundp hook)
                             (setf result (apply hook args))))))))
      (rec hook)
      result)))


(defmacro add-new-hook (hook &rest value)
  "Add a hook. Duplicate it if needed"
  `(setf ,hook (append (typecase ,hook
                         (list ,hook)
                         (t (list ,hook)))
                       (list ,@value))))

(defmacro add-hook (hook &rest value)
  "Add a hook only if not duplicated"
  (let ((i (gensym)))
    `(dolist (,i (list ,@value))
       (unless (member ,i (typecase ,hook
                            (list ,hook)
                            (t (list ,hook))))
         (add-new-hook ,hook ,i)))))

(defmacro remove-hook (hook &rest value)
  (let ((i (gensym)))
    `(dolist (,i (list ,@value) ,hook)
      (setf ,hook (remove ,i ,hook)))))


;;;,-----
;;;| Timers tools
;;;`-----
(defparameter *timer-list* nil)

(declaim (inline realtime->s s->realtime))

(defun realtime->s (rtime)
  (float (/ rtime internal-time-units-per-second)))

(defun s->realtime (second)
  (round (* second internal-time-units-per-second)))


(defun clear-timers ()
  (setf *timer-list* nil))

(defun add-timer (delay fun &optional (id (gensym)))
  "Start the function fun at delay seconds."
  (push (list id
	      (let ((time (+ (get-internal-real-time) (s->realtime delay))))
		(lambda (current-time)
		  (when (>= current-time time)
		    (funcall fun)
		    t))))
	*timer-list*)
  id)

(defun at (delay fun &optional (id (gensym)))
  "Start the function fun at delay seconds."
  (funcall #'add-timer delay fun id))

(defmacro with-timer ((delay &optional (id '(gensym))) &body body)
  "Same thing as add-timer but with syntaxic sugar"
  `(add-timer ,delay
	      (lambda ()
		,@body)
	      ,id))


(defun process-timers ()
  "Call each timers in *timer-list* if needed"
  (let ((current-time (get-internal-real-time)))
    (dolist (timer *timer-list*)
      (when (funcall (second timer) current-time)
        (setf *timer-list* (remove timer *timer-list* :test #'equal))))))

(defun erase-timer (id)
  "Erase the timer identified by its id"
  (setf *timer-list* (remove id *timer-list* :test (lambda (x y)
                                                     (equal x (first y))))))

(defun timer-test-loop ()
  (let ((count 0))
    (labels ((plop ()
               (format t "Plop-~A" count)
               (erase-timer :toto))
             (toto ()
               (format t "Toto-~A" count)
               (add-timer 3 #'toto :toto)))
      (add-timer 3 #'toto :toto)
      (add-timer 13 #'plop)
      (loop
         (princ ".") (force-output)
         (process-timers)
         (sleep 0.5)
         (incf count)))))



;;;,-----
;;;| Debuging tools
;;;`-----
(defvar *%dbg-name%* "dbg")
(defvar *%dbg-count%* 0)


(defmacro dbg (&rest forms)
  `(progn
     ,@(mapcar #'(lambda (form)
		   (typecase form
		     (string `(setf *%dbg-name%* ,form))
		     (number `(setf *%dbg-count%* ,form))))
	       forms)
     (format t "~&DEBUG[~A - ~A]  " (incf *%dbg-count%*) *%dbg-name%*)
     ,@(mapcar #'(lambda (form)
		   (typecase form
		     ((or string number) nil)
		     (t `(format t "~A=~S   " ',form ,form))))
	       forms)
     (format t "~%")
     (force-output)
     ,@forms))

(defmacro dbgnl (&rest forms)
  `(progn
     ,@(mapcar #'(lambda (form)
		   (typecase form
		     (string `(setf *%dbg-name%* ,form))
		     (number `(setf *%dbg-count%* ,form))))
	       forms)
     (format t "~&DEBUG[~A - ~A] --------------------~%" (incf *%dbg-count%*) *%dbg-name%*)
     ,@(mapcar #'(lambda (form)
		   (typecase form
		     ((or string number) nil)
		     (t `(format t "  -  ~A=~S~%" ',form ,form))))
	       forms)
     (force-output)
     ,@forms))


(defun dbgc (obj &optional newline)
  (princ obj)
  (when newline
    (terpri))
  (force-output))


(defun in-rectangle (x y rectangle)
  (and rectangle
       (<= (rectangle-x rectangle) x (+ (rectangle-x rectangle) (rectangle-width rectangle)))
       (<= (rectangle-y rectangle) y (+ (rectangle-y rectangle) (rectangle-height rectangle)))))



(defun distance (x1 y1 x2 y2)
  (+ (abs (- x2 x1)) (abs (- y2 y1))))


;;; Symbols tools
(defun collect-all-symbols (&optional package)
  (format t "Collecting all symbols for Lisp REPL completion...")
  (let (all-symbols)
    (do-symbols (symbol (or package *package*))
      (pushnew (string-downcase (symbol-name symbol)) all-symbols :test #'string=))
    (do-symbols (symbol :keyword)
      (pushnew (concatenate 'string ":" (string-downcase (symbol-name symbol)))
               all-symbols :test #'string=))
    (format t " Done.~%")
    all-symbols))



(defmacro with-all-internal-symbols ((var package) &body body)
  "Bind symbol to all internal symbols in package"
  `(do-symbols (,var ,package)
     (multiple-value-bind (sym status)
	 (find-symbol (symbol-name ,var) ,package)
       (declare (ignore sym))
       (when (eql status :internal)
	 ,@body))))


(defun export-all-functions (package &optional (verbose nil))
  (with-all-internal-symbols (symbol package)
    (when (fboundp symbol)
      (when verbose
	(format t "Exporting ~S~%" symbol))
      (export symbol package))))


(defun export-all-variables (package &optional (verbose nil))
  (with-all-internal-symbols (symbol package)
    (when (boundp symbol)
      (when verbose
	(format t "Exporting ~S~%" symbol))
      (export symbol package))))

(defun export-all-functions-and-variables (package &optional (verbose nil))
  (with-all-internal-symbols (symbol package)
    (when (or (fboundp symbol) (boundp symbol))
      (when verbose
	(format t "Exporting ~S~%" symbol))
      (export symbol package))))



(defun ensure-function (object)
  (if (functionp object)
      object
      (symbol-function object)))




(defun empty-string-p (string)
  (string= string ""))


(defun find-common-string (string list &optional orig)
  "Return the string in common in all string in list"
  (if list
      (let ((result (remove-if-not (lambda (x)
				     (zerop (or (search string x :test #'string-equal) -1)))
				   list)))
	(if (= (length result) (length list))
	    (if (> (length (first list)) (length string))
		(find-common-string (subseq (first list) 0 (1+ (length string))) list string)
		string)
	    orig))
      string))


(defun command-in-path (&optional (tmpfile "/tmp/clfswm-cmd.tmp"))
  (format t "Updating command list for Shell completion...~%")
  (labels ((delete-tmp ()
             (when (probe-file tmpfile)
               (delete-file tmpfile))))
    (delete-tmp)
    (dolist (dir (split-string (getenv "PATH") #\:))
      (ushell (format nil "ls ~A/* >> ~A" dir tmpfile)))
    (let ((commands nil))
      (with-open-file (stream tmpfile :direction :input)
        (loop for line = (read-line stream nil nil)
           while line
           do (pushnew (subseq line (1+ (or (position #\/ line :from-end t) -1))) commands
                       :test #'string=)))
      (delete-tmp)
      (format t "Done. Found ~A commands in shell PATH.~%" (length commands))
      commands)))


;;; Tools
(defmacro setf/= (var val)
  "Set var to val only when var not equal to val"
  (let ((gval (gensym)))
    `(let ((,gval ,val))
       (when (/= ,var ,gval)
	 (setf ,var ,gval)))))


(defun number->char (number)
  (cond ((<= number 25) (code-char (+ (char-code #\a) number)))
        ((<= 26 number 35) (code-char (+ (char-code #\0) (- number 26))))
        ((<= 36 number 61) (code-char (+ (char-code #\A) (- number 36))))
        (t #\|)))

(defun number->string (number)
  (string (number->char number)))

(defun  number->letter (n &optional (base 26))
  (nreverse
   (with-output-to-string (str)
     (labels ((rec (n)
                (princ (code-char (+ (char-code #\a) (mod n base))) str)
                (when (>= n base)
                  (rec (- (truncate (/ n base)) 1)))))
       (rec n)))))


(defun simple-type-of (object)
  (let ((type (type-of object)))
    (typecase type
      (cons (first type))
      (t type))))


(defun repeat-chars (n char)
  "Return a string containing N CHARs."
  (make-string n :initial-element char))



(defun nth-insert (n elem list)
  "Insert elem in (nth n list)"
  (nconc (subseq list 0 n)
	 (list elem)
	 (subseq list n)))



(defun split-string (string &optional (separator #\Space))
  "Return a list from a string splited at each separators"
  (loop for i = 0 then (1+ j)
     as j = (position separator string :start i)
     as sub = (subseq string i j)
     unless (string= sub "") collect sub
     while j))

(defun substring-equal (substring string)
  (string-equal substring (subseq string 0 (min (length substring) (length string)))))

(defun string-match (match list &optional key)
  "Return the string in list witch match the match string"
  (let ((len (length match)))
    (remove-duplicates (remove-if-not (lambda (x)
                                        (string-equal match (subseq x 0 (min len (length x)))))
                                      list
                                      :key key)
                       :test #'string-equal
                       :key key)))


(defun extented-alphanumericp (char)
  (or (alphanumericp char)
      (eq char #\-)
      (eq char #\_)
      (eq char #\.)
      (eq char #\+)
      (eq char #\=)
      (eq char #\*)
      (eq char #\:)
      (eq char #\%)))


(defun append-newline-space (string)
  "Append spaces before Newline on each line"
  (with-output-to-string (stream)
    (loop for c across string do
	 (when (equal c #\Newline)
	   (princ " " stream))
	 (princ c stream))))


(defun expand-newline (list)
  "Expand all newline in strings in list"
  (let ((acc nil))
    (dolist (l list)
      (setf acc (append acc (split-string l #\Newline))))
    acc))

(defun ensure-list (object)
  "Ensure an object is a list"
  (if (listp object)
      object
      (list object)))


(defun ensure-printable (string &optional (new #\?))
  "Ensure a string is printable in ascii"
  (or (substitute-if-not new #'standard-char-p (or string "")) ""))

(defun limit-length (string &optional (length 10))
  (subseq string 0 (min (length string) length)))


(defun ensure-n-elems (list n)
  "Ensure that list has exactly n elements"
  (let ((length (length list)))
    (cond ((= length n) list)
	  ((< length n) (ensure-n-elems (append list '(nil)) n))
	  ((> length n) (ensure-n-elems (butlast list) n)))))

(defun begin-with-2-spaces (string)
  (and (> (length string) 1)
       (eql (char string 0) #\Space)
       (eql (char string 1) #\Space)))

(defun string-equal-p (x y)
  (when (stringp y) (string-equal x y)))




(defun find-assoc-word (word line &optional (delim #\"))
  "Find a word pair"
  (let* ((pos (search word line))
	 (pos-1 (position delim line :start (or pos 0)))
	 (pos-2 (position delim line :start (1+ (or pos-1 0)))))
    (when (and pos pos-1 pos-2)
      (subseq line (1+ pos-1) pos-2))))


(defun print-space (n &optional (stream *standard-output*))
  "Print n spaces on stream"
  (dotimes (i n)
    (princ #\Space stream)))


(defun escape-string (string &optional (escaper '(#\/ #\: #\) #\( #\Space #\; #\,)) (char #\_))
  "Replace in string all characters found in the escaper list"
  (if escaper
      (escape-string (substitute char (car escaper) string) (cdr escaper) char)
      string))



(defun first-position (word string)
  "Return true only if word is at position 0 in string"
  (zerop (or (search word string) -1)))


(defun find-free-number (l)		; stolen from stumpwm - thanks
  "Return a number that is not in the list l."
  (let* ((nums (sort l #'<))
	 (new-num (loop for n from 0 to (or (car (last nums)) 0)
		     for i in nums
		     when (/= n i)
		     do (return n))))
    (if new-num
	new-num
	;; there was no space between the numbers, so use the last + 1
	(if (car (last nums))
	    (1+ (car (last nums)))
	    0))))





;;; Shell part (taken from ltk)
(defun do-execute (program args &optional (wt nil) (io :stream))
  "execute program with args a list containing the arguments passed to
the program   if wt is non-nil, the function will wait for the execution
of the program to return.
   returns a two way stream connected to stdin/stdout of the program"
  #-CLISP (declare (ignore io))
  (let ((fullstring program))
    (dolist (a args)
      (setf fullstring (concatenate 'string fullstring " " a)))
    #+:cmu (let ((proc (ext:run-program program args :input :stream :output :stream :wait wt)))
             (unless proc
               (error "Cannot create process."))
             (make-two-way-stream
              (ext:process-output proc)
              (ext:process-input proc)))
    #+:clisp (ext:run-program program :arguments args :input io :output io :wait wt)
    #+:sbcl (let ((proc (sb-ext:run-program program args :input :stream :output :stream :wait wt)))
	      (unless proc
		(error "Cannot create process."))
	      (make-two-way-stream
	       (sb-ext:process-output proc)
	       (sb-ext:process-input proc)))
    #+:lispworks (system:open-pipe fullstring :direction :io)
    #+:allegro (let ((proc (excl:run-shell-command
			    (apply #'vector program program args)
			    :input :stream :output :stream :wait wt)))
		 (unless proc
		   (error "Cannot create process."))
		 proc)
    #+:ecl (ext:run-program program args :input :stream :output :stream
                            :error :output)
    #+:openmcl (let ((proc (ccl:run-program program args :input
							 :stream :output
							 :stream :wait wt)))
		 (unless proc
		   (error "Cannot create process."))
		 (make-two-way-stream
		  (ccl:external-process-output-stream proc)
		  (ccl:external-process-input-stream proc)))))

(defun do-shell (program &optional args (wait nil) (io :stream))
  (do-execute "/bin/sh" `("-c" ,program ,@args) wait io))

(defun fdo-shell (formatter &rest args)
  (do-shell (apply #'format nil formatter args)))

(defun do-shell-output (formatter &rest args)
  (let ((output (do-shell (apply #'format nil formatter args) nil t)))
    (loop for line = (read-line output nil nil)
       while line
       collect line)))



(defun getenv (var)
  "Return the value of the environment variable."
  #+allegro (sys::getenv (string var))
  #+clisp (ext:getenv (string var))
  #+(or cmu scl)
  (cdr (assoc (string var) ext:*environment-list* :test #'equalp
              :key #'string))
  #+gcl (si:getenv (string var))
  #+lispworks (lw:environment-variable (string var))
  #+lucid (lcl:environment-variable (string var))
  #+(or mcl ccl) (ccl::getenv var)
  #+sbcl (sb-posix:getenv (string var))
  #+ecl (si:getenv (string var))
  #-(or allegro clisp cmu gcl lispworks lucid mcl sbcl scl ecl ccl)
  (error 'not-implemented :proc (list 'getenv var)))


(defun (setf getenv) (val var)
  "Set an environment variable."
  #+allegro (setf (sys::getenv (string var)) (string val))
  #+clisp (setf (ext:getenv (string var)) (string val))
  #+(or cmu scl)
  (let ((cell (assoc (string var) ext:*environment-list* :test #'equalp
							 :key #'string)))
    (if cell
        (setf (cdr cell) (string val))
        (push (cons (intern (string var) "KEYWORD") (string val))
              ext:*environment-list*)))
  #+gcl (si:setenv (string var) (string val))
  #+lispworks (setf (lw:environment-variable (string var)) (string val))
  #+lucid (setf (lcl:environment-variable (string var)) (string val))
  #+sbcl (sb-posix:putenv (format nil "~A=~A" (string var) (string val)))
  #+ecl (si:setenv (string var) (string val))
  #+ccl (ccl::setenv (string var) (string val))
  #-(or allegro clisp cmu gcl lispworks lucid sbcl scl ecl ccl)
  (error 'not-implemented :proc (list '(setf getenv) var)))







(defun uquit ()
  #+(or clisp cmu) (ext:quit)
  #+sbcl (sb-ext:exit)
  #+ecl (si:quit)
  #+gcl (lisp:quit)
  #+lispworks (lw:quit)
  #+(or allegro-cl allegro-cl-trial) (excl:exit)
  #+ccl (ccl:quit))




(defun remove-plist (plist &rest keys)
  "Remove the keys from the plist.
Useful for re-using the &REST arg after removing some options."
  (do (copy rest)
      ((null (setq rest (nth-value 2 (get-properties plist keys))))
       (nreconc copy plist))
    (do () ((eq plist rest))
      (push (pop plist) copy)
      (push (pop plist) copy))
    (setq plist (cddr plist))))




(defun urun-prog (prog &rest opts &key args (wait t) &allow-other-keys)
  "Common interface to shell. Does not return anything useful."
  #+gcl (declare (ignore wait))
  (setq opts (remove-plist opts :args :wait))
  #+allegro (apply #'excl:run-shell-command (apply #'vector prog prog args)
                   :wait wait opts)
  #+(and clisp      lisp=cl)
  (apply #'ext:run-program prog :arguments args :wait wait opts)
  #+(and clisp (not lisp=cl))
  (if wait
      (apply #'lisp:run-program prog :arguments args opts)
      (lisp:shell (format nil "~a~{ '~a'~} &" prog args)))
  #+cmu (apply #'ext:run-program prog args :wait wait :output *standard-output* opts)
  #+gcl (apply #'si:run-process prog args)
  #+liquid (apply #'lcl:run-program prog args)
  #+lispworks (apply #'sys::call-system-showing-output
                     (format nil "~a~{ '~a'~}~@[ &~]" prog args (not wait))
                     opts)
  #+lucid (apply #'lcl:run-program prog :wait wait :arguments args opts)
  #+sbcl (apply #'sb-ext:run-program prog args :wait wait :output *standard-output* opts)
  #+ecl (apply #'ext:run-program prog args opts)
  #+ccl (ccl:run-program prog args :wait wait)
  #-(or allegro clisp cmu gcl liquid lispworks lucid sbcl ecl ccl)
  (error 'not-implemented :proc (list 'run-prog prog opts)))


;;(defparameter *shell-cmd* "/usr/bin/env")
;;(defparameter *shell-cmd-opt* nil)

#+UNIX (defparameter *shell-cmd* "/bin/sh")
#+UNIX (defparameter *shell-cmd-opt* '("-c"))

#+WIN32 (defparameter *shell-cmd* "cmd.exe")
#+WIN32 (defparameter *shell-cmd-opt* '("/C"))


(defun ushell (&rest strings)
  (urun-prog *shell-cmd* :args (append *shell-cmd-opt* strings)))

(defun ush (string)
  (urun-prog *shell-cmd* :args (append *shell-cmd-opt* (list string))))


(defun set-shell-dispatch (&optional (shell-fun 'ushell))
  (labels ((|shell-reader| (stream subchar arg)
	     (declare (ignore subchar arg))
	     (list shell-fun (read stream t nil t))))
    (set-dispatch-macro-character #\# #\# #'|shell-reader|)))


(defun ushell-loop (&optional (shell-fun #'ushell))
  (loop
     (format t "UNI-SHELL> ")
     (let* ((line (read-line)))
       (cond ((zerop (or (search "quit" line) -1)) (return))
	     ((zerop (or (position #\! line) -1))
	      (funcall shell-fun (subseq line 1)))
	     (t (format t "~{~A~^ ;~%~}~%"
			(multiple-value-list
			 (ignore-errors (eval (read-from-string line))))))))))






(defun cldebug (&rest rest)
  (princ "DEBUG: ")
  (dolist (i rest)
    (princ i))
  (terpri))


(defun get-command-line-words ()
  #+sbcl (cdr sb-ext:*posix-argv*)
  #+(or clozure ccl) (cddddr (ccl::command-line-arguments))
  #+gcl (cdr si:*command-args*)
  #+ecl (loop for i from 1 below (si:argc) collect (si:argv i))
  #+cmu (cdddr extensions:*command-line-strings*)
  #+allegro (cdr (sys:command-line-arguments))
  #+lispworks (cdr sys:*line-arguments-list*)
  #+clisp ext:*args*
  #-(or sbcl clozure gcl ecl cmu allegro lispworks clisp)
  (error "get-command-line-arguments not supported for your implementation"))




(defun string-to-list (str &key (split-char #\space))
  (do* ((start 0 (1+ index))
	(index (position split-char str :start start)
	       (position split-char str :start start))
	(accum nil))
       ((null index)
	(unless (string= (subseq str start) "")
	  (push (subseq str start) accum))
	(nreverse accum))
    (when (/= start index)
      (push (subseq str start index) accum))))


(defun near-position (chars str &key (start 0))
  (do* ((char chars (cdr char))
	(pos (position (car char) str :start start)
	     (position (car char) str :start start))
	(ret (when pos pos)
	     (if pos
		 (if ret
		     (if (< pos ret)
			 pos
			 ret)
		     pos)
		 ret)))
       ((null char) ret)))


;;;(defun near-position2 (chars str &key (start 0))
;;;  (loop for i in chars
;;;	minimize (position i str :start start)))

;;(format t "~S~%" (near-position '(#\! #\. #\Space #\;) "klmsqk ppii;dsdsqkl.jldfksj lkm" :start 0))
;;(format t "~S~%" (near-position '(#\Space) "klmsqk ppii;dsdsqkl.jldfksj lkm" :start 0))
;;(format t "~S~%" (near-position '(#\; #\l #\m) "klmsqk ppii;dsdsqkl.jldfksj lkm" :start 0))
;;(format t "result=~S~%" (string-to-list-multichar "klmsqk ppii;dsdsqkl.jldfksj lkm" :preserve t))
;;(format t "result=~S~%" (string-to-list-multichar "klmsqk ppii;dsd!sqkl.jldfksj lkm"
;;						  :split-chars '(#\k  #\! #\. #\; #\m)
;;						  :preserve nil))


(defun string-to-list-multichar (str &key (split-chars '(#\space)) (preserve nil))
  (do* ((start 0 (1+ index))
	(index (near-position split-chars str :start start)
	       (near-position split-chars str :start start))
	(accum nil))
       ((null index)
	(unless (string= (subseq str start) "")
	  (push (subseq str start) accum))
	(nreverse accum))
    (let ((retstr (subseq str start (if preserve (1+ index) index))))
      (unless (string= retstr "")
	(push retstr accum)))))





(defun list-to-string (lst)
  (string-trim " () " (format nil "~A" lst)))



(defun clean-string (string)
  "Remove Newline and upcase string"
  (string-upcase
   (string-right-trim '(#\Newline) string)))

(defun one-in-list (lst)
  (nth (random (length lst)) lst))

(defun exchange-one-in-list (lst1 lst2)
  (let ((elem1 (one-in-list lst1))
	(elem2 (one-in-list lst2)))
    (setf lst1 (append (remove elem1 lst1) (list elem2)))
    (setf lst2 (append (remove elem2 lst2) (list elem1)))
    (values lst1 lst2)))


(defun rotate-list (list)
  (when list
    (append (cdr list) (list (car list)))))

(defun anti-rotate-list (list)
  (when list
    (append (last list) (butlast list))))

(defun n-rotate-list (list steps)
  (when list
    (let* ((len (length list))
           (nsteps (mod steps len)))
      (append (nthcdr nsteps list) (butlast list (- len nsteps))))))


(defun append-formated-list (base-str
			     lst
			     &key (test-not-fun #'(lambda (x) x nil))
			     (print-fun #'(lambda (x) x))
			     (default-str ""))
  (let ((str base-str) (first t))
    (dolist (i lst)
      (cond ((funcall test-not-fun i) nil)
	    (t (setq str
		     (concatenate 'string str
				  (if first "" ", ")
				  (format nil "~A"
					  (funcall print-fun i))))
	       (setq first nil))))
    (if (string= base-str str)
	(concatenate 'string str default-str) str)))


(defun shuffle-list (list &key (time 1))
  "Shuffle a list by swapping elements time times"
  (let ((result (copy-list list))
	(ind1 0) (ind2 0) (swap 0))
    (dotimes (i time)
      (setf ind1 (random (length result)))
      (setf ind2 (random (length result)))

      (setf swap (nth ind1 result))
      (setf (nth ind1 result) (nth ind2 result))
      (setf (nth ind2 result) swap))
    result))



(defun convert-to-number (str)
  (cond ((stringp str) (parse-integer str :junk-allowed t))
	((numberp str) str)))

(defun parse-integer-in-list (lst)
  "Convert all integer string in lst to integer"
  (mapcar #'(lambda (x) (convert-to-number x)) lst))



(defun next-in-list (item lst)
  (do ((x lst (cdr x)))
      ((null x))
    (when (equal item (car x))
      (return (if (cadr x) (cadr x) (car lst))))))

(defun prev-in-list (item lst)
  (next-in-list item (reverse lst)))


(let ((jours '("Lundi" "Mardi" "Mercredi" "Jeudi" "Vendredi" "Samedi" "Dimanche"))
      (mois '("Janvier" "Fevrier" "Mars" "Avril" "Mai" "Juin" "Juillet"
	      "Aout" "Septembre" "Octobre" "Novembre" "Decembre"))
      (days '("Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"))
      (months '("January" "February" "March" "April" "May" "June" "July"
		 "August" "September" "October" "November" "December")))
  (defun date-string ()
    (multiple-value-bind (second minute hour date month year day)
	(get-decoded-time)
      (if (search "fr" (getenv "LANG") :test #'string-equal)
	  (format nil "   ~2,'0D:~2,'0D:~2,'0D    ~A ~2,'0D ~A ~A "
		  hour minute second
		  (nth day jours) date (nth (1- month) mois) year)
	  (format nil "   ~2,'0D:~2,'0D:~2,'0D    ~A ~A ~2,'0D ~A "
		  hour minute second
		  (nth day days) (nth (1- month) months) date year)))))

;;;
;;; Backtrace function
;;;
(defun write-backtrace (filename &optional other-info clear)
  (when (and clear (probe-file filename))
    (delete-file filename))
  (with-open-file (stream filename :direction :output :if-exists :append
                          :if-does-not-exist :create)
    (let ((*standard-output* stream)
          (*debug-io* stream))
      (format t "================== New backtrace ==================~%")
      (format t "--- ~A ---~%" (date-string))
      (format t "Lisp: ~A ; Version: ~A~2%" (lisp-implementation-type)
              (lisp-implementation-version))
      #+clisp (system::print-backtrace)
      #+(or cmucl scl) (debug:backtrace)
      #+sbcl (sb-debug:backtrace)
      #+(or mcl ccl) (ccl:print-call-history :detailed-p nil)
      #-(or clisp cmucl scl sbcl mcl ccl) (format t "Backtrace not defined~%")
      (when other-info
        (format t "~A~%" other-info))
      (format t "--- log end ---~%")))
  (format t "Backtrace logged in file: ~A~%" filename))



;;;
;;; System information functions
;;;
(defparameter *bat-cmd* "acpi -b")
(defparameter *cpu-cmd* "top -b -n 2 -d 1 -p 0")
(defparameter *cpu-cmd-fast* "top -b -n 2 -d 0.1 -p 0")
(defparameter *mem-cmd* "free")

(defmacro with-search-line ((word line) &body body)
  `(let ((pos (search ,word ,line :test #'string-equal)))
    (when (>= (or pos -1) 0)
      ,@body)))

(defun extract-battery-usage (line)
  (with-search-line ("Battery" line)
    (let ((pos (position #\% line)))
      (when pos
        (parse-integer (subseq line (- pos 3) pos) :junk-allowed t)))))

(defun extract-cpu-usage (line)
  (with-search-line ("%Cpu(s):" line)
    (let ((pos1 (search "id" line)))
      (when pos1
        (let ((pos2 (position #\, line :from-end t :end pos1)))
          (when pos2
            (- 100 (parse-integer (subseq line (1+ pos2) pos1) :junk-allowed t))))))))

(defun extract-mem-used (line)
  (with-search-line ("cache:" line)
    (parse-integer (subseq line (+ pos 6)) :junk-allowed t)))

(defun extract-mem-total (line)
  (with-search-line ("mem:" line)
    (parse-integer (subseq line (+ pos 4)) :junk-allowed t)))

(let ((total -1))
  (defun memory-usage ()
    (let ((output (do-shell *mem-cmd*))
          (used -1))
      (loop for line = (read-line output nil nil)
         while line
         do (awhen (extract-mem-used line)
              (setf used it))
           (awhen (and (= total -1) (extract-mem-total line))
             (setf total it)))
      (values used total))))


(defun cpu-usage ()
  (let ((output (do-shell *cpu-cmd-fast*))
        (cpu -1))
    (loop for line = (read-line output nil nil)
       while line
       do (awhen (extract-cpu-usage line)
            (setf cpu it)))
    cpu))

(defun battery-usage ()
  (let ((output (do-shell *bat-cmd*))
        (bat -1))
    (loop for line = (read-line output nil nil)
       while line
       do (awhen (extract-battery-usage line)
            (setf bat it)))
    bat))

(defun battery-alert-string (bat)
  (if (numberp bat)
      (cond ((<= bat 5) "/!\\")
            ((<= bat 10) "!!")
            ((<= bat 25) "!")
            (t ""))
      ""))

;;;
;;; System usage with a poll system - Memory, CPU and battery all in one
;;;
(let ((poll-log "/tmp/.clfswm-system.log")
      (poll-exec "/tmp/.clfswm-system.sh")
      (poll-lock "/tmp/.clfswm-system.lock"))
  (defun create-system-poll (delay)
    (with-open-file (stream poll-exec :direction :output :if-exists :supersede)
      (format stream "#! /bin/sh

while true; do
 (~A; ~A ; ~A) > ~A.tmp;
  mv ~A.tmp ~A;
  sleep ~A;
done~%" *bat-cmd* *cpu-cmd* *mem-cmd* poll-log poll-log poll-log delay)))

  (defun system-poll-pid ()
    (let ((pid nil))
      (let ((output (do-shell "ps x")))
        (loop for line = (read-line output nil nil)
           while line
           do (when (search poll-exec line)
                (push (parse-integer line :junk-allowed t) pid))))
      pid))

  (defun stop-system-poll ()
    (dolist (pid (system-poll-pid))
      (fdo-shell "kill ~A" pid))
    (when (probe-file poll-log)
      (delete-file poll-log))
    (when (probe-file poll-exec)
      (delete-file poll-exec))
    (when (probe-file poll-lock)
      (delete-file poll-lock)))

  (defun start-system-poll (delay)
    (unless (probe-file poll-lock)
      (stop-system-poll)
      (create-system-poll delay)
      (fdo-shell "exec sh ~A" poll-exec)
      (with-open-file (stream poll-lock :direction :output :if-exists :supersede)
        (format stream "CLFSWM system poll started~%"))))

  (defun system-usage-poll (&optional (delay 10))
    (let ((bat -1)
          (cpu -1)
          (used -1)
          (total -1))
      (start-system-poll delay)
      (when (probe-file poll-log)
        (with-open-file (stream poll-log :direction :input)
          (loop for line = (read-line stream nil nil)
             while line
             do (awhen (extract-battery-usage line)
                  (setf bat it))
               (awhen (extract-cpu-usage line)
                 (setf cpu it))
               (awhen (extract-mem-used line)
                 (setf used it))
               (awhen (and (= total -1) (extract-mem-total line))
                 (setf total it)))))
      (values cpu used total bat))))
