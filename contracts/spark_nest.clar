;; SparkNest - Startup Ecosystem Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-user (err u101)) 
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-milestone-not-found (err u104))
(define-constant err-milestone-not-completed (err u105))
(define-constant err-invalid-amount (err u106))
(define-constant err-duplicate-investment (err u107))
(define-constant err-exceeds-funding-goal (err u108))

;; Events
(define-data-var last-event-id uint u0)

(define-map Events
  { event-id: uint }
  {
    event-type: (string-ascii 20),
    startup: principal,
    investor: (optional principal),
    amount: (optional uint),
    milestone-id: (optional uint)
  }
)

;; Enhanced invest function with STX transfer and event tracking
(define-public (invest (startup principal) (amount uint))
    (let (
        (investor-data (get-investor tx-sender))
        (startup-data (get-startup startup))
        (existing-investment (get-investment startup tx-sender))
        (event-id (+ (var-get last-event-id) u1))
    )
        (match startup-data startup-info
            (match investor-data investor-info
                (if (and
                    (> amount u0)
                    (is-none existing-investment)
                    (<= (+ (get funds-raised startup-info) amount) (get funding-goal startup-info))
                )
                    (begin
                        ;; Transfer STX from investor to contract
                        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
                        
                        ;; Update investment records
                        (map-set Investments { startup: startup, investor: tx-sender } {
                            amount: amount,
                            timestamp: block-height,
                            active: true,
                            released-funds: u0
                        })
                        
                        ;; Update startup funds raised
                        (map-set Startups startup (merge startup-info {
                            funds-raised: (+ (get funds-raised startup-info) amount)
                        }))
                        
                        ;; Update investor stats
                        (map-set Investors tx-sender (merge investor-info {
                            total-invested: (+ (get total-invested investor-info) amount),
                            active-investments: (+ (get active-investments investor-info) u1)
                        }))
                        
                        ;; Record event
                        (map-set Events { event-id: event-id }
                            {
                                event-type: "INVESTMENT",
                                startup: startup,
                                investor: (some tx-sender),
                                amount: (some amount),
                                milestone-id: none
                            }
                        )
                        (var-set last-event-id event-id)
                        
                        (ok true)
                    )
                    (if (is-some existing-investment)
                        err-duplicate-investment
                        (if (<= amount u0)
                            err-invalid-amount
                            err-exceeds-funding-goal
                        ))
                )
                err-invalid-user
            )
            err-invalid-user
        )
    )
)

;; [Other functions remain the same...]
