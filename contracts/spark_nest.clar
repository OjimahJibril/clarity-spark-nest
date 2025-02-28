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

;; [Previous data structure definitions remain the same...]

;; Enhanced invest function with proper tracking
(define-public (invest (startup principal) (amount uint))
    (let (
        (investor-data (get-investor tx-sender))
        (startup-data (get-startup startup))
        (existing-investment (get-investment startup tx-sender))
    )
        (match startup-data startup-info
            (match investor-data investor-info
                (if (and
                    (> amount u0)
                    (is-none existing-investment)
                    (<= (+ (get funds-raised startup-info) amount) (get funding-goal startup-info))
                )
                    (begin
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

;; Enhanced add-milestone with validation
(define-public (add-milestone (description (string-ascii 200)) (funds-required uint))
    (let (
        (startup-data (get-startup tx-sender))
    )
        (match startup-data startup-info
            (if (<= (+ funds-required (get funds-raised startup-info)) (get funding-goal startup-info))
                (begin
                    (map-set Milestones 
                        { 
                            startup: tx-sender,
                            milestone-id: (+ (get milestone-count startup-info) u1)
                        }
                        {
                            description: description,
                            funds-required: funds-required,
                            completed: false,
                            approved: false
                        }
                    )
                    (map-set Startups tx-sender (merge startup-info {
                        milestone-count: (+ (get milestone-count startup-info) u1)
                    }))
                    (ok true)
                )
                err-exceeds-funding-goal
            )
            err-invalid-user
        )
    )
)

;; [Other functions remain the same...]
