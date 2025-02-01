;; SparkNest - Startup Ecosystem Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-user (err u101)) 
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-milestone-not-found (err u104))
(define-constant err-milestone-not-completed (err u105))

;; Data Variables
(define-map Startups
    principal
    {
        name: (string-ascii 50),
        description: (string-ascii 500),
        funding-goal: uint,
        funds-raised: uint,
        verified: bool,
        milestone-count: uint
    }
)

(define-map Milestones
    { startup: principal, milestone-id: uint }
    {
        description: (string-ascii 200),
        funds-required: uint,
        completed: bool,
        approved: bool
    }
)

(define-map Mentors
    principal
    {
        name: (string-ascii 50),
        expertise: (string-ascii 100),
        verified: bool,
        reputation: uint
    }
)

(define-map Investors 
    principal
    {
        name: (string-ascii 50),
        total-invested: uint,
        active-investments: uint,
        reputation: uint
    }
)

(define-map Investments
    { startup: principal, investor: principal }
    {
        amount: uint,
        timestamp: uint,
        active: bool,
        released-funds: uint
    }
)

;; Public Functions

;; Register a new startup with milestones
(define-public (register-startup (name (string-ascii 50)) (description (string-ascii 500)) (funding-goal uint))
    (let ((existing-startup (get-startup tx-sender)))
        (if (is-some existing-startup)
            err-already-registered
            (begin
                (map-set Startups tx-sender {
                    name: name,
                    description: description,
                    funding-goal: funding-goal,
                    funds-raised: u0,
                    verified: false,
                    milestone-count: u0
                })
                (ok true)
            )
        )
    )
)

;; Add milestone for startup
(define-public (add-milestone (description (string-ascii 200)) (funds-required uint))
    (let (
        (startup-data (get-startup tx-sender))
    )
        (match startup-data
            startup-info
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
            err-invalid-user
        )
    )
)

;; Complete milestone
(define-public (complete-milestone (milestone-id uint))
    (let (
        (milestone-data (get-milestone tx-sender milestone-id))
    )
        (match milestone-data
            milestone-info
            (begin
                (map-set Milestones
                    { startup: tx-sender, milestone-id: milestone-id }
                    (merge milestone-info { completed: true })
                )
                (ok true)
            )
            err-milestone-not-found
        )
    )
)

;; Approve milestone and release funds
(define-public (approve-milestone (startup principal) (milestone-id uint))
    (let (
        (milestone-data (get-milestone startup milestone-id))
        (investment-data (get-investment startup tx-sender))
    )
        (match milestone-data milestone-info
            (match investment-data investment-info
                (begin
                    (map-set Milestones
                        { startup: startup, milestone-id: milestone-id }
                        (merge milestone-info { approved: true })
                    )
                    (map-set Investments
                        { startup: startup, investor: tx-sender }
                        (merge investment-info {
                            released-funds: (+ (get released-funds investment-info) 
                                             (get funds-required milestone-info))
                        })
                    )
                    (ok true)
                )
                err-invalid-user
            )
            err-milestone-not-found
        )
    )
)

;; Register a new mentor
(define-public (register-mentor (name (string-ascii 50)) (expertise (string-ascii 100)))
    (let ((existing-mentor (get-mentor tx-sender)))
        (if (is-some existing-mentor)
            err-already-registered
            (begin
                (map-set Mentors tx-sender {
                    name: name,
                    expertise: expertise,
                    verified: false,
                    reputation: u0
                })
                (ok true)
            )
        )
    )
)

;; Register a new investor
(define-public (register-investor (name (string-ascii 50)))
    (let ((existing-investor (get-investor tx-sender)))
        (if (is-some existing-investor)
            err-already-registered
            (begin
                (map-set Investors tx-sender {
                    name: name,
                    total-invested: u0,
                    active-investments: u0,
                    reputation: u0
                })
                (ok true)
            )
        )
    )
)

;; Make an investment
(define-public (invest (startup principal) (amount uint))
    (let (
        (investor-data (get-investor tx-sender))
        (startup-data (get-startup startup))
    )
        (if (and (is-some investor-data) (is-some startup-data))
            (begin
                (map-set Investments { startup: startup, investor: tx-sender } {
                    amount: amount,
                    timestamp: block-height,
                    active: true,
                    released-funds: u0
                })
                (ok true)
            )
            err-invalid-user
        )
    )
)

;; Read Only Functions

(define-read-only (get-startup (address principal))
    (map-get? Startups address)
)

(define-read-only (get-mentor (address principal))
    (map-get? Mentors address)
)

(define-read-only (get-investor (address principal))
    (map-get? Investors address)
)

(define-read-only (get-investment (startup principal) (investor principal))
    (map-get? Investments { startup: startup, investor: investor })
)

(define-read-only (get-milestone (startup principal) (milestone-id uint))
    (map-get? Milestones { startup: startup, milestone-id: milestone-id })
)
