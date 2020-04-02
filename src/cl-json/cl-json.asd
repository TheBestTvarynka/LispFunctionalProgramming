;;; -*- lisp -*-
;;; Copyright (c) 2006-2012 Henrik Hjelte
;;; Copyright (c) 2008 Hans Hübner (code from the program YASON)
;;; All rights reserved.
;;; See the file LICENSE for terms of use and distribution.

(in-package #:cl-user)

(defpackage #:json-system
    (:use #:cl #:asdf))

(in-package #:json-system)

(pushnew :cl-json *features*)

#-no-cl-json-clos ;; Does not work with SBCL 1.0.17, this is a way to turn it off
(progn
  #+(or mcl openmcl cmu sbcl clisp ecl scl lispworks allegro)
  (pushnew :cl-json-clos *features*))

(defsystem :cl-json
  :name "cl-json"
  :description "JSON in Lisp. JSON (JavaScript Object Notation) is a lightweight data-interchange format."
  :version "0.5.0"
  :maintainer "Henrik Hjelte <henrik@henrikhjelte.com>"
  :licence "MIT"
  :components ((:static-file "cl-json.asd")
               (:module :src
                :components ((:file "package")
                             (:file "common" :depends-on ("package"))
                             #+cl-json-clos
                             (:file "objects" :depends-on ("package"))
                             (:file "camel-case" :depends-on ("package"))
                             (:file "decoder" :depends-on ("common" #+cl-json-clos "objects" "camel-case"))
                             (:file "encoder" :depends-on ("common" #+cl-json-clos "objects" "camel-case"))
                             (:file "utils" :depends-on ("decoder" "encoder"))
                             (:file "json-rpc" :depends-on ("package" "common" "utils" "encoder" "decoder"))))))

(defparameter *cl-json-directory*
  (make-pathname :directory (pathname-directory *load-truename*)))

