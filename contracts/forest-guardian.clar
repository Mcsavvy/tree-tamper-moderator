;; forest-guardian
;; A Clarity smart contract for detecting and moderating tree tampering events
;; in environmental conservation and forest management systems.
;;
;; This contract enables:
;; - Registering tree locations and baseline health metrics
;; - Reporting potential tampering or unauthorized activities
;; - Tracking forest ecosystem integrity
;; - Incentivizing conservation efforts

;; Error constants
(define-constant ERR-NOT-FOUND (err u200))
(define-constant ERR-UNAUTHORIZED (err u201))
(define-constant ERR-ALREADY-REGISTERED (err u202))
(define-constant ERR-INVALID-REPORT (err u203))
(define-constant ERR-MAX-REPORTS-EXCEEDED (err u204))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-TREE-REPORTS u10)
(define-constant MINIMAL-CONFIDENCE u50)
(define-constant REPORT-REWARD u100)

;; Data structures
(define-map tree-registry
  { tree-id: uint }
  {
    location: (string-utf8 128),
    species: (string-utf8 64),
    initial-health: uint,
    registered-by: principal,
    registration-timestamp: uint
  }
)

(define-map tampering-reports
  { tree-id: uint, reporter: principal }
  {
    confidence-level: uint,
    description: (string-utf8 256),
    timestamp: uint,
    status: (string-ascii 20)  ;; e.g., "pending", "investigated", "resolved"
  }
)

(define-map authorized-monitors
  { monitor: principal }
  { active: bool }
)

;; Data variables
(define-data-var total-registered-trees uint u0)
(define-data-var total-tampering-reports uint u0)

;; Private functions

;; Validate report confidence
(define-private (is-valid-confidence (confidence uint))
  (>= confidence MINIMAL-CONFIDENCE)
)

;; Check if a principal is an authorized monitor
(define-private (is-authorized-monitor (monitor principal))
  (default-to false (get active (map-get? authorized-monitors { monitor: monitor })))
)

;; Public functions

;; Register a new tree in the ecosystem monitoring system
(define-public (register-tree 
  (tree-id uint) 
  (location (string-utf8 128)) 
  (species (string-utf8 64)) 
  (initial-health uint)
)
  (begin
    ;; Prevent duplicate registrations
    (asserts! (is-none (map-get? tree-registry { tree-id: tree-id })) ERR-ALREADY-REGISTERED)
    
    ;; Register tree details
    (map-set tree-registry
      { tree-id: tree-id }
      {
        location: location,
        species: species,
        initial-health: initial-health,
        registered-by: tx-sender,
        registration-timestamp: block-height
      }
    )
    
    ;; Increment total registered trees
    (var-set total-registered-trees (+ (var-get total-registered-trees) u1))
    
    (ok true)
  )
)

;; Report potential tree tampering
(define-public (report-tampering 
  (tree-id uint) 
  (confidence-level uint) 
  (description (string-utf8 256))
)
  (let (
    (current-reports (var-get total-tampering-reports))
  )
    ;; Validate tree exists
    (asserts! (is-some (map-get? tree-registry { tree-id: tree-id })) ERR-NOT-FOUND)
    
    ;; Validate confidence level
    (asserts! (is-valid-confidence confidence-level) ERR-INVALID-REPORT)
    
    ;; Prevent excessive reporting
    (asserts! (< current-reports MAX-TREE-REPORTS) ERR-MAX-REPORTS-EXCEEDED)
    
    ;; Record tampering report
    (map-set tampering-reports
      { tree-id: tree-id, reporter: tx-sender }
      {
        confidence-level: confidence-level,
        description: description,
        timestamp: block-height,
        status: "pending"
      }
    )
    
    ;; Increment total reports
    (var-set total-tampering-reports (+ current-reports u1))
    
    (ok true)
  )
)

;; Manage authorized ecosystem monitors
(define-public (add-monitor (monitor principal))
  (begin
    ;; Only contract owner can add monitors
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    
    (map-set authorized-monitors
      { monitor: monitor }
      { active: true }
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Retrieve tree registration details
(define-read-only (get-tree-details (tree-id uint))
  (map-get? tree-registry { tree-id: tree-id })
)

;; Get total number of registered trees
(define-read-only (get-total-registered-trees)
  (var-get total-registered-trees)
)

;; Get total number of tampering reports
(define-read-only (get-total-tampering-reports)
  (var-get total-tampering-reports)
)

;; Retrieve a specific tampering report
(define-read-only (get-tampering-report (tree-id uint) (reporter principal))
  (map-get? tampering-reports { tree-id: tree-id, reporter: reporter })
)