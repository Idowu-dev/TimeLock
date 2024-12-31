(define-data-var contract-owner principal tx-sender)
(define-map locked-tokens 
    { owner: principal } 
    { amount: uint, unlock-height: uint })

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NO-LOCKED-TOKENS (err u101))
(define-constant ERR-NOT-UNLOCKED (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-TRANSFER-FAILED (err u104))
(define-constant ERR-INVALID-LOCK-PERIOD (err u105))
(define-constant ERR-INVALID-PRINCIPAL (err u106))
(define-constant MAX-LOCK-PERIOD u52560) ;; About 1 year in blocks

;; Check if caller is contract owner
(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner)))

;; Lock tokens for a specified period
(define-public (lock-tokens (lock-period uint))
    (let ((sender tx-sender)
          (amount (stx-get-balance tx-sender)))
        (begin
            (asserts! (> amount u0) ERR-INVALID-AMOUNT)
            (asserts! (and (> lock-period u0) 
                         (<= lock-period MAX-LOCK-PERIOD)) 
                     ERR-INVALID-LOCK-PERIOD)
            (try! (stx-transfer? amount sender (as-contract tx-sender)))
            (map-set locked-tokens
                { owner: sender }
                { amount: amount, 
                  unlock-height: (+ block-height lock-period) })
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

;; Emergency withdrawal by contract owner
(define-public (emergency-withdraw (user principal))
    (let ((locked-data (unwrap! (map-get? locked-tokens { owner: user })
                               ERR-NO-LOCKED-TOKENS))
          (amount (get amount locked-data)))
        (begin
            (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
            ;; Principal validation is handled by the type system
            (map-delete locked-tokens { owner: user })
            (as-contract
                (stx-transfer? amount (as-contract tx-sender) user)))))

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        ;; Principal validation is handled by the type system
        (var-set contract-owner new-owner)
        (ok true)))

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

;; Check if user has locked tokens
(define-read-only (has-locked-tokens (owner principal))
    (is-some (map-get? locked-tokens { owner: owner })))