;; SparkNest - Startup Ecosystem Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-user (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-funds (err u103))

;; Data Variables 
(define-map Startups
    principal
    {
        name: (string-ascii 50),
        description: (string-ascii 500),
        funding-goal: uint,
        funds-raised: uint,
        verified: bool
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
        active: bool
    }
)

;; Public Functions

;; Register a new startup
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
                    verified: false
                })
                (ok true)
            )
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
                    active: true
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