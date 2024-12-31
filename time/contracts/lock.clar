(define-data-var contract-owner principal tx-sender)
(define-map locked-tokens 
    { owner: principal } 
    { amount: uint, unlock-height: uint })

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NO-LOCKED-TOKENS (err u101))
(define-constant ERR-NOT-UNLOCKED (err u102))

;; Lock tokens for a specified period
(define-public (lock-tokens (lock-period uint))
    (let ((sender tx-sender)
          (amount (stx-get-balance tx-sender))
          (unlock-at (+ block-height lock-period)))
        (begin
            (asserts! (> amount u0) (err u103))
            (try! (stx-transfer? amount sender (as-contract tx-sender)))
            (map-set locked-tokens
                { owner: sender }
                { amount: amount, 
                  unlock-height: unlock-at })
            (ok true))))

;; Withdraw tokens after lock period
(define-public (withdraw)
    (let ((locked-data (unwrap! (map-get? locked-tokens { owner: tx-sender })
                               ERR-NO-LOCKED-TOKENS))
          (amount (get amount locked-data))
          (unlock-height (get unlock-height locked-data)))
        (begin
            (asserts! (>= block-height unlock-height) ERR-NOT-UNLOCKED)
            (map-delete locked-tokens { owner: tx-sender })
            (as-contract
                (stx-transfer? amount (as-contract tx-sender) tx-sender)))))

;; Check locked amount
(define-read-only (get-locked-amount (owner principal))
    (match (map-get? locked-tokens { owner: owner })
        locked-data (ok (get amount locked-data))
        ERR-NO-LOCKED-TOKENS))

;; Check unlock height
(define-read-only (get-unlock-height (owner principal))
    (match (map-get? locked-tokens { owner: owner })
        locked-data (ok (get unlock-height locked-data))
        ERR-NO-LOCKED-TOKENS))