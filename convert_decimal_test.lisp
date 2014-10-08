(in-package :nes-unit-testing)

(deftest convert-decimal-test
  (initialize-test-case :env `((remainder-mod8 :byte)))
  (loop for num from 0 upto 255
     do (run-test-case :a num)
        (expect-result :y (floor (/ num 100))
                       :x (mod (floor (/ num 10)) 10)
                       :a (mod num 10)))
  (display-test-timing))
