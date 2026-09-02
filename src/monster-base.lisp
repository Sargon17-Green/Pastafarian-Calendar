(in-package #:pastafari.lv)

(defstruct (monster-context (:constructor %make-monster-context))
  calculation-day
  target-day
  (phase :entry)
  (status :new)
  (semantic-state (make-hash-table :test #'eq))
  (observability-state (make-hash-table :test #'eq)))

(defun make-monster-context (calculation-day target-day)
  (%make-monster-context :calculation-day calculation-day :target-day target-day))

(defstruct (base-dispatcher (:constructor make-base-dispatcher ()))
  (handlers (make-hash-table :test #'eq)))

(defun dispatcher-register (dispatcher phase handler)
  (unless (functionp handler)
    (error "Dispečera apstrādātājam jābūt funkcijai."))
  (setf (gethash phase (base-dispatcher-handlers dispatcher)) handler)
  dispatcher)

(defun dispatcher-dispatch (dispatcher phase context)
  (multiple-value-bind (handler presentp)
      (gethash phase (base-dispatcher-handlers dispatcher))
    (unless presentp
      (error "Dispečerā nav reģistrēta fāze ~S." phase))
    (funcall handler context)))

(defstruct (validation-manager (:constructor make-validation-manager ())))

(defun validation-require (manager condition control &rest arguments)
  (declare (ignore manager))
  (unless condition
    (apply #'error control arguments))
  t)

(define-condition wrapped-monster-error (error)
  ((message :initarg :message :reader wrapped-monster-error-message)
   (cause :initarg :cause :reader wrapped-monster-error-cause))
  (:report (lambda (condition stream)
             (format stream "Monstra kļūdas apvalks: ~A"
                     (wrapped-monster-error-message condition)))))

(defstruct (error-wrapper (:constructor make-error-wrapper ())))

(defun wrap-error (wrapper message cause)
  (declare (ignore wrapper))
  (make-condition 'wrapped-monster-error :message message :cause cause))

(defstruct (metrics-shell (:constructor make-metrics-shell ()))
  (table (make-hash-table :test #'equal)))

(defun metrics-bump (metrics key &optional (amount 1))
  (incf (gethash key (metrics-shell-table metrics) 0) amount))

(defun metrics-read (metrics key)
  (gethash key (metrics-shell-table metrics) 0))

(defstruct (log-shell (:constructor make-log-shell ()))
  (records '()))

(defun log-record (logs code &rest machine-values)
  (push (cons code machine-values) (log-shell-records logs))
  logs)

(defun log-entries (logs)
  (reverse (copy-list (log-shell-records logs))))

(defun calendar-date-spaghetti (calculation-day target-day)
  (declare (ignore calculation-day target-day))
  (error "Ražošanas kalendāra ceļš 1. posmā vēl nav ieviests; vēsturiskos ielāpus iepriekš ieviest nedrīkst."))
