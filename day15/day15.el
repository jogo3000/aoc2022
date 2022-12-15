;;; Summary --- day15.el
;;; Commentary:

;; Sample data holds a picture like this
;;                1    1    2    2
;;      0    5    0    5    0    5
;; -2 ..........#.................
;; -1 .........###................
;;  0 ....S...#####...............
;;  1 .......#######........S.....
;;  2 ......#########S............
;;  3 .....###########SB..........
;;  4 ....#############...........
;;  5 ...###############..........
;;  6 ..#################.........
;;  7 .#########S#######S#........
;;  8 ..#################.........
;;  9 ...###############..........
;; 10 ....B############...........
;; 11 ..S..###########............
;; 12 ......#########.............
;; 13 .......#######..............
;; 14 ........#####.S.......S.....
;; 15 B........###................
;; 16 ..........#SB...............
;; 17 ................S..........B
;; 18 ....S.......................
;; 19 ............................
;; 20 ............S......S........
;; 21 ............................
;; 22 .......................B....
;;; Code:

(require 'seq)

(defun parse-beacon-row (row)
  "Parse stuff from beacon ROW."
  (seq-let (_ xs ys _ xb yb) (split-string row (rx (or "x=" ", y=" ":")))
    (list
     (string-to-number xs)
     (string-to-number ys)
     (string-to-number xb)
     (string-to-number yb))))

(require 'subr-x)

(defun parse-puzzle-input (input)
  "Parse INPUT."
  (thread-last
    (string-chop-newline input)
    (string-lines)
    (seq-map 'parse-beacon-row)))

(defun sensor-covered-area (sensor)
  "Return area covered by SENSOR."
  (seq-let (xs ys xb yb) sensor
    (let ((dx (abs (- xs xb)))
          (dy (abs (- ys yb))))
      (+ dx dy))))

(defun manhattan-distance (p1 p2)
  "Return manhattan distance between P1 and P2."
  (let ((dx (abs (- (car p1) (car p2))))
        (dy (abs (- (cdr p1) (cdr p2)))))
    (+ dx dy)))

(defun read-puzzle-input-from (f)
  "Read puzzle input from F."
  (with-current-buffer (find-file-noselect f)
    (buffer-substring-no-properties (point-min) (point-max))))

(defun point-visible? (p sensors)
  "Return non-nil if point P is visible from SENSORS."
  (seq-some
   (lambda (sensor)
     (let ((distance-to-sensor (manhattan-distance
                                p
                                `(,(cadr sensor) . ,(caddr sensor)))))
       (<= distance-to-sensor (car sensor))))
   sensors))

(defun find-beacons (sensors)
  "Return beacons from SENSORS."
  (seq-map
   (lambda (sensor)
     `(,(seq-elt sensor 2) . ,(seq-elt sensor 3)))
   sensors))

(defun count-covered-points (sensors row start end)
  "Counts points covered by SENSORS on ROW, searcing from START to END."
  (let* ((dsensors (seq-map (lambda (sensor)
                              (cons (sensor-covered-area sensor)
                                    sensor))
                            sensors))
         (beacons (seq-map
                   (lambda (sensor)
                     `(,(seq-elt sensor 2) . ,(seq-elt sensor 3)))
                   sensors))
         (x start)
         (count 0))
    (while (< x end)
      (let ((point `(,x . ,row)))
        (when (and
               (point-visible? point dsensors)
               (not (seq-some (lambda (beacon) (equal point beacon)) beacons)))
          (setq count (+ count 1)))
        (setq x (+ x 1))))
    count))

(thread-first
  (read-puzzle-input-from "./sample-input")
  (parse-puzzle-input)
  (count-covered-points 10 -15 35)
  )

;; sample solution:
;;; In this example, in the row where y=10, there are 26 positions where a beacon cannot be present.
;; 26 - correct!

;; estimate search area
(let ((beacons
       (thread-first
         (read-puzzle-input-from "./input")
         (parse-puzzle-input)
         find-beacons
         )))
  (list (find-min-x beacons)
        (find-max-x beacons)))

(-1236383 3691788)


(thread-first
  (read-puzzle-input-from "./input")
  (parse-puzzle-input)
  (count-covered-points 2000000 -1700000 5000000)
  )

;; 4582667 - Correct!
;; 4208426 - clearly missing the mark
;; 1208426 - too low

;; part 2

;;; Ok so it only makes sense to search by the edges
(defun neighboring-area (sensor)
  "Return points along the edge of the SENSOR covered area."
  (let ((d (sensor-covered-area sensor))
        (points nil)
        (center `(,(elt sensor 0) . ,(elt sensor 1))))
    ;; right - up
    (let ((x (+ (elt sensor 0) d 1))
          (y (elt sensor 1)))
      (while (= (+ d 1) (manhattan-distance `(,x . ,y) center))
        (setq points (cons `(,x . ,y) points))
        (setq x (- x 1))
        (setq y (- y 1))))
    ;; left - up
    (let ((x (- (elt sensor 0) d 1))
          (y (elt sensor 1)))
      (while (= (+ d 1) (manhattan-distance `(,x . ,y) center))
        (setq points (cons `(,x . ,y) points))
        (setq x (+ x 1))
        (setq y (- y 1))))
    ;; right - down
    (let ((x (+ (elt sensor 0) d 1))
          (y (elt sensor 1)))
      (while (= (+ d 1) (manhattan-distance `(,x . ,y) center))
        (setq points (cons `(,x . ,y) points))
        (setq x (- x 1))
        (setq y (+ y 1))))
    ;; left - down
    (let ((x (- (elt sensor 0) d 1))
          (y (elt sensor 1)))
      (while (= (+ d 1) (manhattan-distance `(,x . ,y) center))
        (setq points (cons `(,x . ,y) points))
        (setq x (+ x 1))
        (setq y (+ y 1))))
    (seq-uniq points)))

(defun play-area (points)
  "Return whole play area from POINTS."
  (seq-reduce
   (lambda (acc p)
     (thread-first acc
       (plist-put 'min-x (min (plist-get acc 'min-x) (car p)))
       (plist-put 'max-x (max (plist-get acc 'max-x) (car p)))
       (plist-put 'min-y (min (plist-get acc 'min-y) (cdr p)))
       (plist-put 'max-y (max (plist-get acc 'max-y) (cdr p)))))
   points
   (list 'min-x 100000 'max-x 0 'min-y 0 'max-y 0)))

(defun place-blocked? (map p)
  "Return non-nil when position P is blocked on MAP."
  (seq-find (lambda (pn) (equal pn p)) map))

(defun initialize-map (points)
  "Initialize map from POINTS."
  (let ((limits (play-area points)))
    (vconcat
     (seq-map
      (lambda (y)
        (vconcat
         (seq-map (lambda (x)
                    (cond
                     ((place-blocked? points `(,x . ,y)) "#")
                     (t ".")))
                  (number-sequence (plist-get limits 'min-x) (plist-get limits 'max-x)))))
      (number-sequence (plist-get limits 'min-y) (plist-get limits 'max-y))))))

(defun day15-render (map)
  "Render MAP to a new buffer."
  (with-current-buffer (get-buffer-create "*day15-render*")
    (delete-region (point-min) (point-max))
    (seq-do
     (lambda (row)
       (seq-do
        (lambda (c)
          (insert c))
        row)
       (insert "\n"))
     map)))

(day15-render
 (initialize-map
  (seq-reduce
   (lambda (acc sensor)
     (append acc (neighboring-area sensor)))
   (thread-first
     (read-puzzle-input-from "./sample-input")
     (parse-puzzle-input))
   nil)))

(defun search-area (sensors)
  "Determine search area from SENSORS."
  (seq-reduce
   (lambda (acc sensor)
     (append acc (neighboring-area sensor)))
   sensors
   nil))

(defun find-uncovered-point (sensors max-x max-y)
  "Find the point that is not covered by SENSORS."
  (let* ((dsensors (seq-map (lambda (sensor)
                              (cons (sensor-covered-area sensor)
                                    sensor))
                            sensors))
         (beacons (seq-map
                   (lambda (sensor)
                     `(,(seq-elt sensor 2) . ,(seq-elt sensor 3)))
                   sensors)))

    (seq-some
     (lambda (point)
       (when (and
              (<= 0 (car point) max-x)
              (<= 0 (cdr point) max-y)
              (not (point-visible? point dsensors))
              (not (seq-some (lambda (beacon) (equal point beacon)) beacons)))
         point))
     (search-area sensors))))

(let ((x (find-uncovered-point
          (thread-first
            (read-puzzle-input-from "./sample-input")
            (parse-puzzle-input))
          20 20)))
  (+ (* 4000000 (car x))
     (cdr x)))
;; 56000011 - correct!


(let ((x (find-uncovered-point
          (thread-first
            (read-puzzle-input-from "./input")
            (parse-puzzle-input))
           4000000 4000000)))
  (+ (* 4000000 (car x))
     (cdr x)))


;; sample map
"
               1    1    2    2
     0    5    0    5    0    5
-2 ..........#.................
-1 .........###................
 0 ....S...#####...............
 1 .......#######........S.....
 2 ......#########S............
 3 .....###########SB..........
 4 ....#############...........
 5 ...###############..........
 6 ..#################.........
 7 .#########S#######S#........
 8 ..#################.........
 9 ...###############..........
10 ....B############...........
11 ..S..###########............
12 ......#########.............
13 .......#######..............
14 ........#####.S.......S.....
15 B........###................
16 ..........#SB...............
17 ................S..........B
18 ....S.......................
19 ............................
20 ............S......S........
21 ............................
22 .......................B....
"
;; (2 . 26)
;; (7 . 21) How... ah! I see!


;;; day15.el ends here
